-- Core schema for DreamScape neuromorphic XR sleep stack (REM-excluded)

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE lab_tenant (
    tenant_id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name               VARCHAR(255) NOT NULL,
    iso13485_scope     VARCHAR(255) NOT NULL,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL
);

CREATE TABLE rem_policy (
    policy_id          UUID PRIMARY KEY,
    label              VARCHAR(128) NOT NULL,
    version            VARCHAR(32)  NOT NULL,
    description        VARCHAR(512) NOT NULL,
    rem_excluded       BOOLEAN      NOT NULL DEFAULT TRUE,
    effective_from     TIMESTAMP    NOT NULL,
    effective_to       TIMESTAMP,
    created_at         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL,
    qms_doc_ref        VARCHAR(64),
    CHECK (rem_excluded = TRUE)
);

CREATE OR REPLACE FUNCTION rem_policy_block_mods()

RETURNS trigger AS $$
BEGIN
    RAISE EXCEPTION 'rem_policy is immutable; insert new version instead.';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_rem_policy_block_ud
BEFORE UPDATE OR DELETE ON rem_policy
FOR EACH ROW EXECUTE FUNCTION rem_policy_block_mods();

CREATE TABLE subject (
    subject_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id          UUID NOT NULL REFERENCES lab_tenant(tenant_id),
    pseudonym_code     VARCHAR(64) NOT NULL UNIQUE,
    year_of_birth      INT,
    sex_at_birth       VARCHAR(16),
    notes              VARCHAR(1024),
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL
);

CREATE TABLE subject_identity_vault (
    vault_id           BIGSERIAL PRIMARY KEY,
    subject_id         UUID NOT NULL UNIQUE REFERENCES subject(subject_id),
    given_name_hash    CHAR(64) NOT NULL,
    family_name_hash   CHAR(64) NOT NULL,
    dob_full_enc       BYTEA    NOT NULL,
    contact_enc        BYTEA,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL
);

CREATE TABLE reidentification_log (
    log_id             BIGSERIAL PRIMARY KEY,
    subject_id         UUID NOT NULL,
    actor_id           VARCHAR(128) NOT NULL,
    purpose_code       VARCHAR(64) NOT NULL,
    legal_basis        VARCHAR(64) NOT NULL,
    requested_at       TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    approved_by        VARCHAR(128),
    approved_at        TIMESTAMP,
    details            JSONB
);

CREATE TABLE device_family (
    family_code        VARCHAR(64) PRIMARY KEY,
    class              VARCHAR(32) NOT NULL,
    description        VARCHAR(512) NOT NULL,
    iso13485_relevant  BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE device_asset (
    device_id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id          UUID NOT NULL REFERENCES lab_tenant(tenant_id),
    family_code        VARCHAR(64) NOT NULL REFERENCES device_family(family_code),
    manufacturer_model VARCHAR(128),
    serial_number      VARCHAR(128),
    location_label     VARCHAR(128),
    active             BOOLEAN NOT NULL DEFAULT TRUE,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL
);

CREATE TABLE calibration_profile (
    profile_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    family_code        VARCHAR(64) NOT NULL REFERENCES device_family(family_code),
    profile_name       VARCHAR(128) NOT NULL,
    target_rms_mm      NUMERIC(6,3),
    max_rms_mm         NUMERIC(6,3),
    target_bias_pct    NUMERIC(5,2),
    max_bias_pct       NUMERIC(5,2),
    target_cv_pct      NUMERIC(5,2),
    max_cv_pct         NUMERIC(5,2),
    max_interval_days  INT NOT NULL,
    notes              VARCHAR(1024),
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL
);

CREATE TABLE calibration_certificate (
    cert_id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    provider_name      VARCHAR(255) NOT NULL,
    provider_accred    VARCHAR(128),
    cert_number        VARCHAR(128) NOT NULL,
    cert_issue_date    DATE         NOT NULL,
    cert_expiry_date   DATE,
    traceable_to_std   VARCHAR(255),
    document_uri       VARCHAR(512),
    created_at         TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL
);

CREATE TABLE calibration_certificate_link (
    parent_cert_id     UUID NOT NULL REFERENCES calibration_certificate(cert_id),
    child_cert_id      UUID NOT NULL REFERENCES calibration_certificate(cert_id),
    relation           VARCHAR(64) NOT NULL,
    PRIMARY KEY (parent_cert_id, child_cert_id)
);

CREATE TABLE calibration_record (
    cal_id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    device_id          UUID NOT NULL REFERENCES device_asset(device_id),
    profile_id         UUID NOT NULL REFERENCES calibration_profile(profile_id),
    cert_id            UUID REFERENCES calibration_certificate(cert_id),
    performed_on       TIMESTAMP NOT NULL,
    performed_by       VARCHAR(128) NOT NULL,
    passed             BOOLEAN NOT NULL,
    rms_error_mm       NUMERIC(6,3),
    bias_pct           NUMERIC(5,2),
    cv_pct             NUMERIC(5,2),
    results_json       JSONB,
    action_taken       VARCHAR(512),
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL
);

CREATE TABLE facility_context (
    facility_id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id          UUID NOT NULL REFERENCES lab_tenant(tenant_id),
    type               VARCHAR(16) NOT NULL,
    description        VARCHAR(512),
    requires_ded_room  BOOLEAN NOT NULL DEFAULT FALSE,
    requires_phantom   BOOLEAN NOT NULL DEFAULT FALSE,
    min_staff_trained  INT NOT NULL DEFAULT 1,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL
);

CREATE TABLE study (
    study_id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    tenant_id          UUID NOT NULL REFERENCES lab_tenant(tenant_id),
    study_code         VARCHAR(64) NOT NULL UNIQUE,
    title              VARCHAR(255) NOT NULL,
    study_type         VARCHAR(32) NOT NULL,
    rem_sleep_allowed  BOOLEAN NOT NULL DEFAULT FALSE,
    rem_policy_id      UUID NOT NULL REFERENCES rem_policy(policy_id),
    irb_protocol_id    VARCHAR(128),
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL,
    CHECK (rem_sleep_allowed = FALSE)
);

CREATE TABLE xr_session (
    session_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    study_id           UUID NOT NULL REFERENCES study(study_id),
    subject_id         UUID NOT NULL REFERENCES subject(subject_id),
    facility_id        UUID NOT NULL REFERENCES facility_context(facility_id),
    started_at         TIMESTAMP NOT NULL,
    ended_at           TIMESTAMP,
    purpose            VARCHAR(64) NOT NULL,
    rem_flag           BOOLEAN NOT NULL DEFAULT FALSE,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL,
    CHECK (rem_flag = FALSE)
);

CREATE TABLE xr_session_device (
    session_id         UUID NOT NULL REFERENCES xr_session(session_id),
    device_id          UUID NOT NULL REFERENCES device_asset(device_id),
    role               VARCHAR(64) NOT NULL,
    PRIMARY KEY (session_id, device_id)
);

CREATE TABLE eeg_recording (
    eeg_id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id         UUID NOT NULL REFERENCES xr_session(session_id),
    device_id          UUID NOT NULL REFERENCES device_asset(device_id),
    montage_code       VARCHAR(64) NOT NULL,
    sampling_hz        NUMERIC(6,2) NOT NULL,
    classifier_version VARCHAR(64),
    summary_features   JSONB,
    quality_flag       VARCHAR(32) NOT NULL,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL
);

CREATE TABLE biosignal_summary (
    summary_id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id         UUID NOT NULL REFERENCES xr_session(session_id),
    device_id          UUID NOT NULL REFERENCES device_asset(device_id),
    metric_type        VARCHAR(32) NOT NULL,
    value              NUMERIC(12,4) NOT NULL,
    unit               VARCHAR(32) NOT NULL,
    window_start       TIMESTAMP NOT NULL,
    window_end         TIMESTAMP NOT NULL,
    quality_flag       VARCHAR(32) NOT NULL,
    created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_by         VARCHAR(128) NOT NULL
);

CREATE TABLE audit_event (
    audit_id           BIGSERIAL PRIMARY KEY,
    tenant_id          UUID NOT NULL REFERENCES lab_tenant(tenant_id),
    actor_id           VARCHAR(128) NOT NULL,
    action             VARCHAR(64) NOT NULL,
    entity_type        VARCHAR(64) NOT NULL,
    entity_id          VARCHAR(64) NOT NULL,
    event_time         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    details            JSONB
);

CREATE VIEW device_last_pass_cal AS
SELECT
    c.device_id,
    MAX(c.performed_on) AS last_passed_on
FROM calibration_record c
WHERE c.passed = TRUE
GROUP BY c.device_id;

CREATE OR REPLACE FUNCTION flag_overdue_calibration()

RETURNS trigger AS $$
DECLARE
    v_last_passed   TIMESTAMP;
    v_max_interval  INT;
BEGIN
    SELECT MAX(c.performed_on), cp.max_interval_days
    INTO v_last_passed, v_max_interval
    FROM calibration_record c
    JOIN calibration_profile cp ON cp.profile_id = c.profile_id
    WHERE c.device_id = NEW.device_id
      AND c.passed = TRUE
    GROUP BY cp.max_interval_days;

    IF v_last_passed IS NULL THEN
        RAISE EXCEPTION 'Device % has no valid calibration.', NEW.device_id;
    ELSIF (CURRENT_DATE - v_last_passed::date) > v_max_interval THEN
        RAISE EXCEPTION 'Device % calibration overdue.', NEW.device_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_session_device_cal_guard
BEFORE INSERT ON xr_session_device
FOR EACH ROW EXECUTE FUNCTION flag_overdue_calibration();

CREATE OR REPLACE FUNCTION prevent_rem_labels()

RETURNS trigger AS $$
BEGIN
    IF NEW.study_type ILIKE '%REM%' OR NEW.title ILIKE '%REM%' THEN
        RAISE EXCEPTION 'REM-related study labeling is prohibited.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_study_no_rem
BEFORE INSERT OR UPDATE ON study
FOR EACH ROW EXECUTE FUNCTION prevent_rem_labels();

CREATE OR REPLACE FUNCTION prevent_rem_sessions()

RETURNS trigger AS $$
BEGIN
    IF NEW.purpose ILIKE '%REM%' OR NEW.rem_flag = TRUE THEN
        RAISE EXCEPTION 'REM-related sessions are prohibited.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_session_no_rem
BEFORE INSERT OR UPDATE ON xr_session
FOR EACH ROW EXECUTE FUNCTION prevent_rem_sessions();
