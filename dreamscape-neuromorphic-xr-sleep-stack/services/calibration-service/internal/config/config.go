package config

import "github.com/kelseyhightower/envconfig"

type Config struct {
    HTTPPort  string `envconfig:"HTTP_PORT" default:"8081"`
    DBURL     string `envconfig:"DB_URL" required:"true"`
    ServiceID string `envconfig:"SERVICE_ID" default:"calibration-service"`
}

func Load() (Config, error) {
    var c Config
    err := envconfig.Process("CALIB", &c)
    return c, err
}
