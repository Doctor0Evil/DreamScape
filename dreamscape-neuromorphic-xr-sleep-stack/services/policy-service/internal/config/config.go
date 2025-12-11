package config

import "github.com/kelseyhightower/envconfig"

type Config struct {
    HTTPPort   string `envconfig:"HTTP_PORT" default:"8080"`
    DBURL      string `envconfig:"DB_URL" required:"true"`
    ServiceID  string `envconfig:"SERVICE_ID" default:"policy-service"`
    PolicyID   string `envconfig:"REM_POLICY_ID" default:"99999999-9999-4999-8999-999999999999"`
}

func Load() (Config, error) {
    var c Config
    err := envconfig.Process("POLICY", &c)
    return c, err
}
