# syntax=docker/dockerfile:1

FROM golang:1.23-alpine AS builder
WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/ah-mcp .

FROM alpine:3.20
RUN addgroup -S app && adduser -S app -G app \
    && apk add --no-cache ca-certificates tzdata \
    && mkdir -p /home/app/.config/ah-mcp \
    && chown -R app:app /home/app

USER app
WORKDIR /home/app

COPY --from=builder /out/ah-mcp /usr/local/bin/ah-mcp

ENV AH_CALLBACK_HOST=http://localhost:9876 \
    AH_CALLBACK_PORT=9876 \
    AH_MCP_PORT=3000 \
    AH_MCP_BASE_URL=http://localhost:3000 \
    AH_REMOTE=false

EXPOSE 3000 9876

ENTRYPOINT ["/usr/local/bin/ah-mcp"]
CMD ["--transport", "streamable-http"]
