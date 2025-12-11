# Calibration Service

Minimal service to check if a device is in calibration based on `calibration_record` and `calibration_profile`.

Build and run (local)

```powershell
$env:CALIB_HTTP_PORT = '8081'
$env:CALIB_DB_URL = 'postgres://dreamscape_app:testpassword@localhost:5432/dreamscape?sslmode=disable'

cd services/calibration-service
go build ./cmd
.
```

Endpoints
- `GET /v1/calibration/check?device_id=<uuid>` - verifies if device is in calibration.

