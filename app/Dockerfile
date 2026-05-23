# syntax=docker/dockerfile:1.7
ARG COMMIT=dev
ARG TAG=dev

FROM golang:1.25-alpine AS build
WORKDIR /src
COPY . .
RUN go mod tidy
ARG COMMIT
ARG TAG
RUN CGO_ENABLED=0 GOOS=linux GOFLAGS="-trimpath" \
    go build -ldflags="-s -w -X main.commit=${COMMIT} -X main.tag=${TAG}" \
    -o /out/app ./cmd/app

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/app /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
