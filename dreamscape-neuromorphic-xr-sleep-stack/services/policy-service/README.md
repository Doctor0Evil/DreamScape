# Policy Service

This is a minimal, production-oriented policy service for DreamScape.
It validates `StudyDescriptor` and `SessionDescriptor` entities against a REM-exclusion policy stored in Postgres.

Build and run (local)

```powershell
# Set env vars (example)
$env:POLICY_HTTP_PORT = '8080'
$env:POLICY_DB_URL = 'postgres://dreamscape_app:testpassword@localhost:5432/dreamscape?sslmode=disable'
$env:POLICY_REM_POLICY_ID = '99999999-9999-4999-8999-999999999999'

cd services/policy-service
go build ./cmd
.
```

Notes
- Uses `envconfig` to load environment variables prefixed with `POLICY_`.
- The CI pipeline will insert the manifest `rem_exclusion_manifest_v1_0_0.json` into `rem_policy` table.
