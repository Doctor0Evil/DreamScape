package main

import (
    "context"
    "log"
    stdhttp "net/http"
    "os"
    "os/signal"
    "syscall"
    "time"

    chi "github.com/go-chi/chi/v5"

    "github.com/dreamscape-xr/calibration-service/internal/calib"
    "github.com/dreamscape-xr/calibration-service/internal/config"
    "github.com/dreamscape-xr/calibration-service/internal/db"
    httph "github.com/dreamscape-xr/calibration-service/internal/http"
)

func main() {
    cfg, err := config.Load()
    if err != nil {
        log.Fatalf("config error: %v", err)
    }

    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()

    database, err := db.Connect(ctx, cfg.DBURL)
    if err != nil {
        log.Fatalf("db connect error: %v", err)
    }
    defer database.Pool.Close()

    svc := calib.NewService(database)
    h := httph.NewHandler(svc)

    r := chi.NewRouter()
    r.Get("/v1/calibration/check", h.CheckCalibration)
    r.Handle("/metrics", httph.MetricsHandler())

    srv := &stdhttp.Server{
        Addr:         ":" + cfg.HTTPPort,
        Handler:      r,
        ReadTimeout:  5 * time.Second,
        WriteTimeout: 10 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    go func() {
        log.Printf("calibration-service listening on :%s", cfg.HTTPPort)
        if err := srv.ListenAndServe(); err != nil && err != stdhttp.ErrServerClosed {
            log.Fatalf("server error: %v", err)
        }
    }()

    sigCh := make(chan os.Signal, 1)
    signal.Notify(sigCh, syscall.SIGINT, syscall.SIGTERM)
    <-sigCh

    shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
    defer shutdownCancel()
    _ = srv.Shutdown(shutdownCtx)
}
