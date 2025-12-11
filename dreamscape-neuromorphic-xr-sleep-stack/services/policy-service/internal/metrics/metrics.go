package metrics

import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promauto"
)

var (
    PolicyRequestsTotal = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "policy_requests_total",
            Help: "Total number of policy validation requests by type and result.",
        },
        []string{"type", "result"},
    )
)
