package policy

import "context"

type StudyDescriptor struct {
    ID            string `json:"id"`
    StudyCode     string `json:"study_code"`
    Title         string `json:"title"`
    StudyType     string `json:"study_type"`
    RemAllowed    bool   `json:"rem_sleep_allowed"`
    RemPolicyID   string `json:"rem_policy_id"`
}

type SessionDescriptor struct {
    ID        string `json:"id"`
    StudyID   string `json:"study_id"`
    Purpose   string `json:"purpose"`
    RemFlag   bool   `json:"rem_flag"`
}

type Service interface {
    ValidateStudy(ctx context.Context, d StudyDescriptor) error
    ValidateSession(ctx context.Context, d SessionDescriptor) error
}
