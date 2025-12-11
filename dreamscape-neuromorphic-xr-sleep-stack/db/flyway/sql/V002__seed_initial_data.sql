-- Seed REM-exclusion policy, default tenant, and device families

INSERT INTO lab_tenant (tenant_id, name, iso13485_scope, created_by)
VALUES (
    '11111111-1111-4111-8111-111111111111',
    'DreamScape Default Tenant',
    'Neuromorphic XR sleep-support platform; non-REM interventions',
    'seed-script-v1_0_0'
)
ON CONFLICT (tenant_id) DO NOTHING;

INSERT INTO rem_policy (
    policy_id,
    label,
    version,
    description,
    rem_excluded,
    effective_from,
    created_by,
    qms_doc_ref
) VALUES (
    '99999999-9999-4999-8999-999999999999',
    'REM-EXCLUDED-DREAMSCAPE-XR',
    '1.0.0',
    'Initial DreamScape REM-exclusion policy; prohibits REM sleep and dream-phase integrations.',
    TRUE,
    NOW(),
    'seed-script-v1_0_0',
    'QMS-POL-REM-001'
)
ON CONFLICT (policy_id) DO NOTHING;

INSERT INTO device_family (family_code, class, description, iso13485_relevant)
VALUES
('XR_HMD', 'XR_DISPLAY', 'Clinical-grade XR headset for relaxation and insomnia support.', TRUE),
('EEG_HEADBAND', 'BIOSENSING', 'EEG headband for arousal and sleep-stage monitoring.', TRUE),
('BIOSENSE_FRONTEND', 'BIOSENSING', 'Multiplex biosensing front-end for non-sleep analytes.', TRUE)
ON CONFLICT (family_code) DO NOTHING;
