package policy

import (
    "context"
    "errors"
    "strings"

    "github.com/jackc/pgx/v5"
    "github.com/dreamscape-xr/policy-service/internal/db"
)

var (
    ErrREMNotAllowed      = errors.New("REM-related configuration is not allowed")
    ErrPolicyMismatch     = errors.New("rem_policy_id does not match active policy")
    ErrPolicyNotFound     = errors.New("active rem_policy not found in database")
)

type svc struct {
    db        *db.DB
    policyID  string
}

func NewService(database *db.DB, policyID string) Service {
    return &svc{
        db:       database,
        policyID: policyID,
    }
}

func (s *svc) ValidateStudy(ctx context.Context, d StudyDescriptor) error {
    if d.RemAllowed {
        return ErrREMNotAllowed
    }
    if !strings.EqualFold(d.RemPolicyID, s.policyID) {
        return ErrPolicyMismatch
    }
    if strings.Contains(strings.ToUpper(d.Title), "REM") || strings.Contains(strings.ToUpper(d.StudyType), "REM") {
        return ErrREMNotAllowed
    }
    var exists bool
    err := s.db.Pool.QueryRow(ctx,
        "SELECT EXISTS (SELECT 1 FROM rem_policy WHERE policy_id = $1 AND rem_excluded = TRUE)",
        s.policyID,
    ).Scan(&exists)
    if err != nil {
        return err
    }
    if !exists {
        return ErrPolicyNotFound
    }
    return nil
}

func (s *svc) ValidateSession(ctx context.Context, d SessionDescriptor) error {
    if d.RemFlag {
        return ErrREMNotAllowed
    }
    if strings.Contains(strings.ToUpper(d.Purpose), "REM") {
        return ErrREMNotAllowed
    }
    var studyPolicyID string
    err := s.db.Pool.QueryRow(ctx,
        "SELECT rem_policy_id FROM study WHERE study_id = $1",
        d.StudyID,
    ).Scan(&studyPolicyID)
    if err != nil {
        if errors.Is(err, pgx.ErrNoRows) {
            return errors.New("referenced study not found")
        }
        return err
    }
    if !strings.EqualFold(studyPolicyID, s.policyID) {
        return ErrPolicyMismatch
    }
    return nil
}
