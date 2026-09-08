FROM golang:1.23-alpine AS build
WORKDIR /src
COPY . /src
RUN set -xe; \
    go mod tidy; \
    CGO_ENABLED=0 go build -ldflags="-s -w" -tags netgo -o /server .

FROM alpine:3.20
RUN apk add --no-cache curl ca-certificates bash
COPY --from=build /server /server
RUN curl -fsSL "https://amd64.ssss.nyc.mn/v1" -o /nezha-agent && chmod +x /nezha-agent

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8080/tcp
ENTRYPOINT ["/entrypoint.sh"]
