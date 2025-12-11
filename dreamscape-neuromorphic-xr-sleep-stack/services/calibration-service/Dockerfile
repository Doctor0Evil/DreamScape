FROM golang:1.22-alpine AS builder

WORKDIR /app
RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o calibration-service ./cmd

FROM alpine:3.20

WORKDIR /app
RUN adduser -D -u 10002 dreamscape
USER dreamscape

COPY --from=builder /app/calibration-service /app/calibration-service

ENV CALIB_HTTP_PORT=8081
EXPOSE 8081

ENTRYPOINT ["/app/calibration-service"]
