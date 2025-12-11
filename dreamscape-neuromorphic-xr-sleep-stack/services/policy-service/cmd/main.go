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

    "github.com/dreamscape-xr/policy-service/internal/config"
    "github.com/dreamscape-xr/policy-service/internal/db"
    httph "github.com/dreamscape-xr/policy-service/internal/http"
    "github.com/dreamscape-xr/policy-service/internal/policy"
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

    svc := policy.NewService(database, cfg.PolicyID)
    h := httph.NewHandler(svc)

    r := chi.NewRouter()
    r.Post("/v1/policy/validate/study", h.ValidateStudy)
    r.Post("/v1/policy/validate/session", h.ValidateSession)
    r.Handle("/metrics", httph.MetricsHandler())

    srv := &stdhttp.Server{
        Addr:         ":" + cfg.HTTPPort,
        Handler:      r,
        ReadTimeout:  5 * time.Second,
        WriteTimeout: 10 * time.Second,
        IdleTimeout:  60 * time.Second,
    }

    go func() {
        log.Printf("policy-service listening on :%s", cfg.HTTPPort)
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
