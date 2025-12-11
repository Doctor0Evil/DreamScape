package httph

import (
    "encoding/json"
    stdhttp "net/http"

    "github.com/dreamscape-xr/calibration-service/internal/calib"
    "github.com/dreamscape-xr/calibration-service/internal/metrics"
)

type Handler struct {
    svc calib.Service
}

func NewHandler(s calib.Service) *Handler {
    return &Handler{svc: s}
}

type calibResponse struct {
    DeviceID       string `json:"device_id"`
    InCalibration  bool   `json:"in_calibration"`
}

func (h *Handler) CheckCalibration(w stdhttp.ResponseWriter, r *stdhttp.Request) {
    deviceID := r.URL.Query().Get("device_id")
    if deviceID == "" {
        w.WriteHeader(stdhttp.StatusBadRequest)
        _ = json.NewEncoder(w).Encode(map[string]string{"error": "device_id required"})
        return
    }
    ok, err := h.svc.IsDeviceInCalibration(r.Context(), deviceID)
    if err != nil {
        metrics.CalibrationChecksTotal.WithLabelValues("error").Inc()
        w.WriteHeader(stdhttp.StatusInternalServerError)
        _ = json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
        return
    }
    label := "out_of_calibration"
    if ok {
        label = "in_calibration"
    }
    metrics.CalibrationChecksTotal.WithLabelValues(label).Inc()
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(calibResponse{
        DeviceID:      deviceID,
        InCalibration: ok,
    })
}

package httph

import (
    "encoding/json"
    "net/http"

    "github.com/dreamscape-xr/calibration-service/internal/metrics"
    "github.com/dreamscape-xr/calibration-service/internal/calib"
)

    deviceID := r.URL.Query().Get("device_id")
    if deviceID == "" {
        w.WriteHeader(stdhttp.StatusBadRequest)
        _ = json.NewEncoder(w).Encode(map[string]string{"error": "device_id required"})

func NewHandler(s calib.Service) *Handler {
    return &Handler{svc: s}
}
        metrics.CalibrationChecksTotal.WithLabelValues("error").Inc()
        w.WriteHeader(stdhttp.StatusInternalServerError)
        _ = json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
    DeviceID       string `json:"device_id"`
    InCalibration  bool   `json:"in_calibration"`
}

func (h *Handler) CheckCalibration(w http.ResponseWriter, r *http.Request) {
    deviceID := r.URL.Query().Get("device_id")
    if deviceID == "" {
        w.WriteHeader(http.StatusBadRequest)
        _ = json.NewEncoder(w).Encode(map[string]string{"error": "device_id required"})
        return
    }
    ok, err := h.svc.IsDeviceInCalibration(r.Context(), deviceID)
    if err != nil {
        w.WriteHeader(http.StatusInternalServerError)
        _ = json.NewEncoder(w).Encode(map[string]string{"error": err.Error()})
        return
    }
    w.Header().Set("Content-Type", "application/json")
    _ = json.NewEncoder(w).Encode(calibResponse{
        DeviceID:      deviceID,
        InCalibration: ok,
    })
}
