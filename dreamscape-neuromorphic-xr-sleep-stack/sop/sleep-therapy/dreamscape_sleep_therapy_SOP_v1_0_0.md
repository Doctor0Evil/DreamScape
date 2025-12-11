# DreamScape Sleep Therapy SOP v1.0.0

## Purpose

Provide a clinical SOP for XR-based pre-sleep therapy delivery (relaxation, CBT-I modules, and arousal-focused closed-loop adaptations) consistent with safety constraints and REM-exclusion guarantees.

## Scope

Applies to clinical deployments implementing DreamScape's evidence-aligned pre-sleep and insomnia support modules.

## Procedure (Summary)

1. Pre-session checks:
   - Verify study and session are validated by `policy-service` and bound to the active `rem_policy`.
   - Confirm all devices in `xr_session_device` have valid calibration records within their `calibration_profile` max interval.
   - Ensure `subject` is registered and has a pseudonym code; identity vault should not be accessed except via approved reidentification processes.
2. Session setup:
   - Load therapy graph for the planned session; confirm node ordering and allowed durations.
   - Configure classifier versions and default safety bounds (max brightness, max audio intensity, max session length).
3. During session:
   - If EEG-guided arousal rises above clinician-defined thresholds, adapt XR content towards lower arousal modules until stable.
   - On detection of REM-like signals or when `rem_flag` is set erroneously, terminate or fade-out content and notify the clinician.
4. Post-session:
   - Store summary features in `eeg_recording.summary_features` and `biosignal_summary`.
   - Write `audit_event` entries for all closed-loop decisions that changed therapy intensity.
   - If reidentification is required for safety, insert into `reidentification_log` with purpose and legal basis.
