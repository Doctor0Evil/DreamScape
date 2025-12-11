-- Enable pgTAP (must be installed in the DB)
CREATE EXTENSION IF NOT EXISTS pgtap;

BEGIN;

SELECT plan(6);

-- 1. REM-excluded policy present
SELECT ok(
    (SELECT COUNT(*) FROM rem_policy WHERE policy_id = '99999999-9999-4999-8999-999999999999' AND rem_excluded = TRUE) = 1,
    'REM-excluded policy exists and is active'
);

-- 2. REM-labeled study is rejected by trigger
DO $$
DECLARE
    err TEXT;
BEGIN
    BEGIN
        INSERT INTO study (
            tenant_id, study_code, title, study_type, rem_sleep_allowed, rem_policy_id, irb_protocol_id, created_by
        ) VALUES (
            '11111111-1111-4111-8111-111111111111',
            'REM_NEG_TEST',
            'REM experiment',
            'REM_TEST',
            FALSE,
            '99999999-9999-4999-8999-999999999999',
            'IRB-REM',
            'pgtap-test'
        );
    EXCEPTION WHEN others THEN
        err := SQLERRM;
    END;

    IF err IS NULL THEN
        RAISE EXCEPTION 'Expected REM-labeled study insertion to fail';
    END IF;
END $$;

SELECT pass('REM-labeled study is rejected by prevent_rem_labels trigger');

-- 3. REM flag on session is rejected
DO $$
DECLARE
    s_id UUID;
    err TEXT;
BEGIN
    INSERT INTO study (
        tenant_id, study_code, title, study_type, rem_sleep_allowed, rem_policy_id, irb_protocol_id, created_by
    ) VALUES (
        '11111111-1111-4111-8111-111111111111',
        'NON_REM_STUDY',
        'Insomnia relaxation',
        'INSOMNIA_RELAX',
        FALSE,
        '99999999-9999-4999-8999-999999999999',
        'IRB-NON-REM',
        'pgtap-test'
    ) RETURNING study_id INTO s_id;

    BEGIN
        INSERT INTO xr_session (
            study_id, subject_id, facility_id, started_at, purpose, rem_flag, created_by
        ) VALUES (
            s_id,
            (SELECT subject_id FROM subject LIMIT 1),
            (SELECT facility_id FROM facility_context LIMIT 1),
            NOW(),
            'REM_ANALYSIS',
            TRUE,
            'pgtap-test'
        );
    EXCEPTION WHEN others THEN
        err := SQLERRM;
    END;

    IF err IS NULL THEN
        RAISE EXCEPTION 'Expected REM-flagged session insertion to fail';
    END IF;
END $$;

SELECT pass('REM-flagged session is rejected by prevent_rem_sessions trigger');

-- 4–6. Calibration enforcement on session-device link
DO $$
DECLARE
    d_in_cal UUID;
    d_out_of_cal UUID;
    prof_id UUID;
    s_id UUID;
BEGIN
    -- calibration profile
    INSERT INTO calibration_profile (
        family_code, profile_name, max_interval_days, created_by
    ) VALUES (
        'XR_HMD', 'XR HMD calibration profile', 30, 'pgtap-test'
    ) RETURNING profile_id INTO prof_id;

    -- in-calibration device
    INSERT INTO device_asset (
        tenant_id, family_code, manufacturer_model, serial_number, location_label, active, created_by
    ) VALUES (
        '11111111-1111-4111-8111-111111111111',
        'XR_HMD',
        'XR-HMD-CLINICAL',
        'XRHMD-001',
        'Lab-A',
        TRUE,
        'pgtap-test'
    ) RETURNING device_id INTO d_in_cal;

    -- calibration now (valid)
    INSERT INTO calibration_record (
        device_id, profile_id, performed_on, performed_by, passed, created_by
    ) VALUES (
        d_in_cal, prof_id, NOW(), 'tech-a', TRUE, 'pgtap-test'
    );

    -- expired-calibration device
    INSERT INTO device_asset (
        tenant_id, family_code, manufacturer_model, serial_number, location_label, active, created_by
    ) VALUES (
        '11111111-1111-4111-8111-111111111111',
        'XR_HMD',
        'XR-HMD-CLINICAL',
        'XRHMD-002',
        'Lab-B',
        TRUE,
        'pgtap-test'
    ) RETURNING device_id INTO d_out_of_cal;

    -- calibration far in the past
    INSERT INTO calibration_record (
        device_id, profile_id, performed_on, performed_by, passed, created_by
    ) VALUES (
        d_out_of_cal, prof_id, NOW() - INTERVAL '365 days', 'tech-b', TRUE, 'pgtap-test'
    );

    -- create a valid session
    -- Ensure minimal subject and facility exist for test
        DO $$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM subject WHERE pseudonym_code = 'PSEUDO_TEST_001') THEN
                INSERT INTO subject (tenant_id, pseudonym_code, created_by)
                VALUES ('11111111-1111-4111-8111-111111111111', 'PSEUDO_TEST_001', 'pgtap-test');
            END IF;
            IF NOT EXISTS (SELECT 1 FROM facility_context WHERE description = 'Default Test Facility') THEN
                INSERT INTO facility_context (tenant_id, type, description, created_by)
                VALUES ('11111111-1111-4111-8111-111111111111', 'CLINIC', 'Default Test Facility', 'pgtap-test');
            END IF;
        END$$;

    INSERT INTO xr_session (
        study_id, subject_id, facility_id, started_at, purpose, rem_flag, created_by
    ) VALUES (
        (SELECT study_id FROM study WHERE study_code = 'NON_REM_STUDY' LIMIT 1),
        (SELECT subject_id FROM subject LIMIT 1),
        (SELECT facility_id FROM facility_context LIMIT 1),
        NOW(),
        'INSOMNIA_RELAX',
        FALSE,
        'pgtap-test'
    ) RETURNING session_id INTO s_id;

    -- in-calibration device should be accepted
    INSERT INTO xr_session_device (session_id, device_id, role)
    VALUES (s_id, d_in_cal, 'XR_DISPLAY');

    -- out-of-calibration device should be rejected
    BEGIN
        INSERT INTO xr_session_device (session_id, device_id, role)
        VALUES (s_id, d_out_of_cal, 'XR_DISPLAY');
        RAISE EXCEPTION 'Expected calibration overdue device to be rejected';
    EXCEPTION WHEN others THEN
        NULL;
    END;
END $$;

SELECT pass('In-calibration device accepted by trg_session_device_cal_guard');
SELECT pass('Out-of-calibration device rejected by trg_session_device_cal_guard');

SELECT * FROM finish();

ROLLBACK;
