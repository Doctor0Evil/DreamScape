# DreamScape DB Tests (pgTAP)

These tests verify core safety invariants directly in PostgreSQL using pgTAP:
- REM exclusion: REM-labeled studies and sessions must be rejected.
- Calibration enforcement: devices with missing or overdue calibration cannot be attached to sessions.

To run locally:
1. Install pgTAP extension in the target Postgres instance (e.g., via PGXN or distro packages).
2. Apply Flyway migrations (V001/V002).
3. Run: psql -d dreamscape -f db/tests/test_rem_and_calibration.sql
