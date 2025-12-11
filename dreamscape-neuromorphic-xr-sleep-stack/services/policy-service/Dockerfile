FROM golang:1.22-alpine AS builder

WORKDIR /app
RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN go build -o policy-service ./cmd

FROM alpine:3.20

WORKDIR /app
RUN adduser -D -u 10001 dreamscape
USER dreamscape

COPY --from=builder /app/policy-service /app/policy-service

ENV POLICY_HTTP_PORT=8080
EXPOSE 8080

ENTRYPOINT ["/app/policy-service"]
