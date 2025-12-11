# DreamScape Neuromorphic XR Sleep Stack

DreamScape is a neuromorphic, AR/VR-first platform for evidence-aligned sleep support (relaxation, insomnia, and anxiety), explicitly excluding REM-content manipulation while enabling clinical-grade XR + EEG/BCI workflows under ISO 13485-style quality controls.[^4_1][^4_2][^4_3]

## Scope and Principles

- Focus: pre-sleep relaxation, adjunctive insomnia support, and anxiety reduction using immersive XR, not dream or REM-content control.[^4_4][^4_5]
- Safety: REM-phase integrations are technically excluded at database, policy, and service levels; all closed loops are arousal-focused and conservative.
- Compliance orientation: Schema and services are structured to support ISO 13485 QMS, ISO 14971 risk management, and data-privacy regulations (e.g., GDPR/HIPAA) when integrated into a certified environment.[^4_2][^4_6][^4_1]
- Scientific grounding: Architecture follows published XR-for-sleep and EEG/BCI literature, using VR as an adjunct to standard therapies such as CBT-I.[^4_3][^4_5][^4_4]

This repository provides production-ready scaffolding (no placeholders) for a multi-service stack: DB schema, policy artifacts (ALN), XR orchestration, EEG gateway, calibration and policy services, analytics, and documented SOPs.

## High-Level Architecture

Layers:

1. Clinical knowledge and regulatory layer
    - Encodes therapy graphs, REM-exclusion policy, and device calibration rules as versioned ALN artifacts.
    - Provides policy-service APIs for other services to validate sessions, studies, and classifier usage against active policies.
2. Therapy orchestration and XR layer
    - `xr-orchestrator` service plans sessions, obtains policy clearance, and drives XR engines (Unity/Unreal) via stable protocols.
    - Client apps (clinic dashboard, patient app) interact only through the API gateway.
3. Neuromorphic inference and EEG closed-loop layer
    - `eeg-gateway` streams EEG and biosignal summaries into neuromorphic classifiers and adapts XR intensity for arousal reduction within fixed safety bounds.[^4_7]
    - REM is observed only for fade-out and safety, not to manipulate content.
4. Data and analytics layer
    - Central Postgres schema for devices, calibration, studies, sessions, EEG summaries, and audit events.
    - `analytics-service` exposes reporting APIs and aggregates metrics for clinical and product analytics.
5. Infrastructure and observability
    - Kubernetes manifests and Terraform templates are organized for cloud deployment.
    - Observability includes structured logs, metrics, and traces, with strict handling of pseudonymized identifiers.

## Core Directories

- `db/schema`: Versioned SQL schemas (e.g., `dreamscape_neuro_xr_v1_0_0.sql`) with:
    - REM-exclusion constraints and immutable policy metadata.
    - Calibration traceability fields and pseudonymization tables with reidentification logs.
- `db/migrations`: Ordered SQL migration scripts (V001+).
- `db/seeds`: Minimal seed data (device families, default REM-exclusion policy).
- `aln/policies`: REM-exclusion and calibration/usage ALN modules, versioned and immutable.
- `aln/therapy_graphs`: CBT-I-aligned therapy graphs and XR module definitions.
- `aln/manifests`: JSON manifests linking policy IDs, ALN files, and git commits for auditability.
- `services/*`: Rust/Go services, each with `src` and `config`, intended for containerized deployment.
- `clients/*`: Frontend clients for clinicians and patients, designed for secure, pseudonymized interaction with the backend.
- `infra/*`: Kubernetes, Terraform, and observability configuration with production readiness.
- `sop/*`: Markdown SOPs for calibration, XR therapy, and privacy/pseudonymization.
- `docs/*`: Architecture documentation, regulatory mapping, and mathematical proof outlines for closed-loop safety properties.
- `hardware/*`: Neuromorphic XR headset and biosensing rig BOM and interface documentation.

## Testing and CI

- Flyway is used for schema migrations (see `db/flyway`). CI runs Flyway migrations and basic smoke tests via GitHub Actions and GitLab CI.
- DB unit tests are written using pgTAP under `db/tests`. Use `tools/scripts/run_db_tests.sh` to run tests locally once Postgres is available and `pgtap` is installed in the server environment.
- Manifests in `aln/manifests` are validated in CI, and `git_commit` gets injected by the pipeline for traceability.

## Security and Key Management
- See `docs/security/hsm_identity_vault_design_v1_0_0.md` for design notes about HSM-backed encryption for the `subject_identity_vault` and reidentification auditing practices.

## Local Development (Docker)

We provide a `docker-compose.yml` and `Makefile` to simplify local development by running Postgres, applying Flyway DB migrations, and starting the Go microservices.

Quick start:

```bash
# Start Postgres, run Flyway migrations, then start services
make up

# Show service logs
make logs

# Run DB tests (requires pgTAP to be installed in the Postgres container)
make db-test

# Stop and cleanup
make down
```

Notes:
- The local `docker-compose.yml` uses `dreamscape_dev` as the DB password for development; do not use this in production.
- The `flyway-migrate` container runs migrations from `db/flyway/sql`.

Monitoring:

- Prometheus is included in the `docker-compose.yml` for local dev and listens on `http://localhost:9090`.
- Each service exposes Prometheus metrics on `/metrics`:
    - `policy-service` -> `http://localhost:8080/metrics`
    - `calibration-service` -> `http://localhost:8081/metrics`

Query example (Prometheus console):
    - `policy_requests_total` — total validation requests by type/result
    - `calibration_checks_total` — total calibration checks
- The services build using local `Dockerfile` artifacts and expose `8080` (policy-service) and `8081` (calibration-service).




## Safety and REM-Exclusion Guarantees

- Schema-level constraints:
    - `study.rem_sleep_allowed = FALSE` and `CHECK` constraints blocking REM-labeled types or titles.
    - `xr_session.rem_flag = FALSE` with triggers rejecting any REM-tagged sessions.
- Policy-level constraints:
    - ALN `RemExclusionPolicy` modules require `rem_sleep_allowed == false` and `rem_flag == false` in all validated descriptors.
- Runtime enforcement:
    - Policy service validates study and session descriptors and rejects non-compliant payloads before XR or EEG services act.
    - EEG closed loops can fade out or stop content when REM-like patterns are detected; they never inject or alter dream content.


## ISO 13485-Oriented Traceability

The schema and services implement:

- Device and calibration traceability:
    - Every device has a family, model, serial, current status, location, and calibration profile.
    - Calibration records link devices to calibration profiles and certificate chains with dates, results, and operator roles.[^4_8][^4_1]
- Record control and audit trails:
    - All critical changes are written to `audit_event` with actor, action, entity type, and details JSON.[^4_6][^4_2]
- Pseudonymized subjects:
    - Operational data uses pseudonymized subject IDs and codes; direct identifiers live only in a separate identity vault with encrypted fields.
    - All reidentification accesses are logged in `reidentification_log` with purpose and legal basis.[^4_9][^4_3]


## Mathematical Provability and Safety Invariants

The stack is designed for formalization of core invariants:

- REM-exclusion invariants:
    - For all sessions `s`, `s.rem_flag = false` and `s.study.rem_sleep_allowed = false`.
    - No policy artifact in ALN can enable REM-specific modules; manifests and DB policies are linked and immutable.
- Calibration invariants:
    - For any session-device link, the device's last passed calibration is within the profile-defined maximum interval, or the insertion is rejected.
- Pseudonymization invariants:
    - Operational DB never stores direct identifiers.
    - Any reidentification event is accompanied by a log record with actor, purpose, and timestamp.

These invariants can be used as the basis for model checking, property-based tests, and formal verification over the schema and policy layer.

## Legal and Clinical Positioning

- This repository is designed to support, but not by itself guarantee, compliance with:
    - ISO 13485 for QMS structure and documentation control.
    - ISO 14971 for hazard and risk management in neuromorphic XR sleep-support systems.
    - Data-protection frameworks (e.g., GDPR, HIPAA) in deployments with appropriate governance.[^4_1][^4_2][^4_6]
- Clinical use as a medical device requires:
    - Proper QMS, clinical evidence, and regulatory submissions by the deploying organization.
    - Oversight from qualified healthcare professionals for insomnia treatment indications.[^4_5][^4_4]

EOF