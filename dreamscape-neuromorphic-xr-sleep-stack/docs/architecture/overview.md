# DreamScape Neuromorphic XR Architecture Overview

This document explains the main services, data flows, and safety invariants for the DreamScape neuromorphic XR sleep-support stack.

## Services

- `policy-service`: Loads ALN policies and manifests, exposes validation APIs for studies and sessions, and ensures alignment with REM-exclusion and calibration policies.
- `xr-orchestrator`: Plans and manages XR sessions, applying policy validations before launch and logging all decisions.
- `eeg-gateway`: Handles EEG and biosignal acquisition, runs neuromorphic or low-power inference models, and sends arousal signals to the orchestrator.
- `calibration-service`: Manages device registration, calibration profiles, calibration records, and certificate chains.
- `analytics-service`: Aggregates pseudonymized data for outcomes analysis and regulatory reporting.
- `api-gateway`: Provides authenticated, audited entry points for clients.


## Safety and Provable Invariants

The architecture is built to support formal reasoning over:

- REM-exclusion: enforced by DB constraints, ALN policy modules, and policy-service checks.
- Calibration validity: enforced by triggers on session-device links and calibration-service logic.
- Pseudonymization and logging: enforced by strict schema separation and mandatory reidentification logs.

