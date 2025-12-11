# DreamScape Calibration SOP v1.0.0

## Purpose

Define mandatory steps to ensure all XR, EEG, and biosensing devices used by DreamScape operate within validated calibration limits consistent with ISO 13485-aligned practices.[^4_8][^4_1]

## Scope

Applies to all clinical and research deployments of DreamScape where device measurements are used for sleep-support decision making or clinical studies.

## Procedure (Summary)

1. Pre-check: Verify device registration, current status, and calibration due dates in the central database; if no valid calibration or calibration overdue, device must not be used.
2. Environment preparation: Ensure calibration phantoms, markers, wands, and environmental conditions meet specification.
3. Calibration execution: Perform calibration following device-specific procedures; verify RMS, bias, and CV values against `calibration_profile`.
4. Verification: Run functional checks and compare basic metrics with historical or reference values.
5. Documentation: Record calibration details in `calibration_record`, attach certificate references, and ensure creation of associated `audit_event` entries for traceability.[^4_2][^4_1][^4_8]

