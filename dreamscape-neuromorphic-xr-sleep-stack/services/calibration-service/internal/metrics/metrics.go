package metrics

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    CalibrationChecksTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "calibration_checks_total",
            Help: "Total number of calibration checks by result.",
        },
        []string{"result"},
    )
)
