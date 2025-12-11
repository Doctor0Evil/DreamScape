package httph

import (
    "encoding/json"
    stdhttp "net/http"

    "github.com/dreamscape-xr/policy-service/internal/metrics"
    "github.com/dreamscape-xr/policy-service/internal/policy"
)

type Handler struct {
    svc policy.Service
}

func NewHandler(s policy.Service) *Handler {
    return &Handler{svc: s}
}

func writeJSON(w stdhttp.ResponseWriter, status int, payload any) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    _ = json.NewEncoder(w).Encode(payload)
}

func (h *Handler) ValidateStudy(w http.ResponseWriter, r *http.Request) {
    var d policy.StudyDescriptor
    if err := json.NewDecoder(r.Body).Decode(&d); err != nil {
        metrics.PolicyRequestsTotal.WithLabelValues("study", "bad_request").Inc()
        writeJSON(w, stdhttp.StatusBadRequest, map[string]string{"error": "invalid_json"})
        return
    }
    if err := h.svc.ValidateStudy(r.Context(), d); err != nil {
        metrics.PolicyRequestsTotal.WithLabelValues("study", "rejected").Inc()
        writeJSON(w, stdhttp.StatusUnprocessableEntity, map[string]string{"error": err.Error()})
        return
    }
    metrics.PolicyRequestsTotal.WithLabelValues("study", "accepted").Inc()
    writeJSON(w, stdhttp.StatusOK, map[string]string{"status": "ok"})
}

func (h *Handler) ValidateSession(w http.ResponseWriter, r *http.Request) {
    var d policy.SessionDescriptor
    if err := json.NewDecoder(r.Body).Decode(&d); err != nil {
        metrics.PolicyRequestsTotal.WithLabelValues("session", "bad_request").Inc()
        writeJSON(w, stdhttp.StatusBadRequest, map[string]string{"error": "invalid_json"})
        return
    }
    if err := h.svc.ValidateSession(r.Context(), d); err != nil {
        metrics.PolicyRequestsTotal.WithLabelValues("session", "rejected").Inc()
        writeJSON(w, stdhttp.StatusUnprocessableEntity, map[string]string{"error": err.Error()})
        return
    }
    metrics.PolicyRequestsTotal.WithLabelValues("session", "accepted").Inc()
    writeJSON(w, stdhttp.StatusOK, map[string]string{"status": "ok"})
}
