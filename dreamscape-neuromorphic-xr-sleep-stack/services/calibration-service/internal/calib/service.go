package calib

import (
    "context"
    "errors"
    "time"

    "github.com/dreamscape-xr/calibration-service/internal/db"
)

type Service interface {
    IsDeviceInCalibration(ctx context.Context, deviceID string) (bool, error)
}

type svc struct {
    db *db.DB
}

var ErrDeviceUnknown = errors.New("device not found")

func NewService(database *db.DB) Service {
    return &svc{db: database}
}

func (s *svc) IsDeviceInCalibration(ctx context.Context, deviceID string) (bool, error) {
    var lastPassed time.Time
    var maxDays int
    err := s.db.Pool.QueryRow(ctx, `
        SELECT MAX(c.performed_on) AS last_passed_on,
               cp.max_interval_days
        FROM calibration_record c
        JOIN calibration_profile cp ON cp.profile_id = c.profile_id
        WHERE c.device_id = $1
          AND c.passed = TRUE
        GROUP BY cp.max_interval_days
    `, deviceID).Scan(&lastPassed, &maxDays)
    if err != nil {
        return false, err
    }
    if lastPassed.IsZero() {
        return false, ErrDeviceUnknown
    }
    overdue := time.Since(lastPassed).Hours() > float64(24*maxDays)
    return !overdue, nil
}
