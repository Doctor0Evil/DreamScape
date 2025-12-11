#!/usr/bin/env bash
set -euo pipefail

: ${PGHOST:=localhost}
: ${PGPORT:=5432}
: ${PGDATABASE:=dreamscape}
: ${PGUSER:=dreamscape_app}
: ${PGPASSWORD:=testpassword}

export PGPASSWORD

echo "Attempting to create pgtap extension if available..."
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -c "CREATE EXTENSION IF NOT EXISTS pgtap;" || true

echo "Running pgTAP tests in db/tests/test_rem_and_calibration.sql (may fail if extension is unavailable)"
psql -h "$PGHOST" -p "$PGPORT" -U "$PGUSER" -d "$PGDATABASE" -f db/tests/test_rem_and_calibration.sql

echo "pgTAP tests complete."
