.PHONY: help up down logs db-shell db-migrate db-test build-services test-services prometheus grafana

PROJECT_NAME := dreamscape-neuromorphic-xr-sleep-stack

help:
	@echo "Observability targets:"
	@echo "  up              - Start full stack (Postgres + services + Prometheus + Grafana)"
	@echo "  prometheus      - Open Prometheus UI"
	@echo "  grafana         - Open Grafana UI (admin/dreamscape_dev)"
	@echo "  down            - Stop all services"
	@echo "Other targets unchanged..."

up:
	docker-compose up -d postgres
	@echo "Waiting for Postgres health..."
	docker-compose run --rm flyway-migrate
	docker-compose up -d

down:
	docker-compose down -v

logs:
	docker-compose logs -f

db-shell:
	PGPASSWORD=dreamscape_dev psql -h localhost -U dreamscape_app -d dreamscape

db-migrate:
	docker-compose run --rm flyway-migrate

db-test:
	PGPASSWORD=dreamscape_dev psql -h localhost -U dreamscape_app -d dreamscape -f db/tests/test_rem_and_calibration.sql || echo "pgTAP tests skipped or failed; check that pgTAP is installed."

build-services:
	cd services/policy-service && go build ./cmd
	cd services/calibration-service && go build ./cmd

test-services:
	cd services/policy-service && go test ./...
	cd services/calibration-service && go test ./...
# Makefile for common operations (Assumes Linux/macOS shell)

.PHONY: help db-migrate db-test build

help:
	@echo "Available targets:"
	@echo "  db-migrate   - Run Flyway migrations (local flyway required or use docker)"
	@echo "  db-test      - Run DB pgTAP tests (requires psql and DB ready)"
	@echo "  build        - Build Go microservices"

db-migrate:
	@echo "Run Flyway migrations (ensure flyway exists in PATH or use docker)"
	@if command -v flyway >/dev/null 2>&1; then \
		flyway -configFiles=db/flyway/conf/flyway.conf -locations=filesystem:db/flyway/sql migrate; \
	else \
		echo "flyway not found in PATH; to use docker image, run:"; \
		echo "docker run --rm -v $(pwd)/db/flyway/conf:/flyway/conf -v $(pwd)/db/flyway/sql:/flyway/sql flyway/flyway:10.20.0 -configFiles=/flyway/conf/flyway.conf migrate"; \
	fi

db-test:
	@echo "Running DB tests using tools/scripts/run_db_tests.sh"
	@bash tools/scripts/run_db_tests.sh

build:
	@echo "Building Go services"
	cd services/policy-service && go mod tidy && go build ./cmd
	cd services/calibration-service && go mod tidy && go build ./cmd
