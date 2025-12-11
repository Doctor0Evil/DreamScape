-- Minimal seed data for DreamScape

-- Insert a default REM-exclusion policy (policy_id same as ALN manifest)
INSERT INTO rem_policy (policy_id, label, version, description, rem_excluded, effective_from, created_by, qms_doc_ref)
VALUES ('99999999-9999-4999-8999-999999999999', 'REM-EXCLUDED-DREAMSCAPE-XR', '1.0.0', 'Default REM exclusion policy used for initial seed.', TRUE, now(), 'seed-script', 'QMS-POL-REM-001')
ON CONFLICT (policy_id) DO NOTHING;

-- Insert some default device families
INSERT INTO device_family (family_code, class, description)
VALUES
('HMD_GEN_V1', 'HMD', 'Clinical-grade AR/VR headset with integrated biosensors'),
('EEG_HEADBAND_V1', 'BIOSENSING', '8-channel dry-electrode EEG headband for sleep and arousal detection'),
('IMU_BODY_V1', 'IMU', 'Wearable inertial measurement unit for movement and posture')
ON CONFLICT (family_code) DO NOTHING;

-- Insert a demo tenant
INSERT INTO lab_tenant (tenant_id, name, iso13485_scope, created_by)
VALUES (uuid_generate_v4(), 'DreamScape Demo Tenant', 'Clinical Research and Pilot Deployments', 'seed-script');
