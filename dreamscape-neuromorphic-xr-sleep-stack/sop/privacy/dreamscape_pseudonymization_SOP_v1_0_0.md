# DreamScape Pseudonymization and Reidentification SOP v1.0.0

## Purpose

Describe how subject data is pseudonymized in the DreamScape stack and how reidentification events are controlled and logged in compliance-oriented environments.[^4_3][^4_9]

## Pseudonymization Model

- Operational data uses `subject.subject_id` and `pseudonym_code` only.
- Direct identifiers (names, full date of birth, contact details) are stored exclusively in `subject_identity_vault` with hashed or encrypted fields.
- Access to the identity vault is technically restricted and requires documented justification.


## Reidentification Control

- Any reidentification action requires:
    - Valid purpose (e.g., safety alert, incidental finding follow-up, legal obligation).
    - Legal basis documented in the request (e.g., consent, statutory requirement).
- When identity data is accessed for a subject:
    - A record is inserted into `reidentification_log` with subject_id, actor_id, purpose_code, legal_basis, and timestamps.
- Regular audits review `reidentification_log` entries to ensure access remains necessary and proportionate.

