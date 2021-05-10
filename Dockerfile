#syntax=docker/dockerfile:1.2
# Build the manager binary
FROM golang:1.16 as builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN --mount=type=cache,target=/go/pkg/mod go mod download

FROM builder AS controller-builder
COPY .git/ .git/
COPY api/ api/
COPY controllers/ controllers/
COPY main.go .
RUN go generate ./api/util/version.go
RUN --mount=type=cache,target=/root/.cache/go-build CGO_ENABLED=0 go build -a -o bin/manager main.go

FROM gcr.io/distroless/static:nonroot AS controller
WORKDIR /
COPY --from=controller-builder /workspace/bin/manager .
COPY config/kafka-default.yaml /config/
COPY config/stan-default.yaml /config/
USER 9653:9653
ENTRYPOINT ["/manager"]

FROM builder AS runner-builder
COPY .git/ .git/
COPY api/ api/
COPY runner/ runner/
RUN go generate ./api/util/version.go
RUN --mount=type=cache,target=/root/.cache/go-build CGO_ENABLED=0 go build -a -o bin/runner ./runner
COPY kill/ kill/
RUN --mount=type=cache,target=/root/.cache/go-build CGO_ENABLED=0 go build -a -o bin/kill ./kill

FROM gcr.io/distroless/static:nonroot AS runner
WORKDIR /
COPY runtimes runtimes
COPY --from=runner-builder /workspace/bin/runner .
COPY --from=runner-builder /workspace/bin/kill /bin/kill
USER 9653:9653
ENTRYPOINT ["/runner"]

FROM golang:1.16-alpine AS go1-16
RUN mkdir /.cache
ADD runtimes/go1-16 /workspace
RUN chown -R 9653 /.cache /workspace
WORKDIR /workspace
USER 9653:9653
ENTRYPOINT ./entrypoint.sh

FROM openjdk:16 AS java16
ADD runtimes/java16 /workspace
RUN chown -R 9653 /workspace
WORKDIR /workspace
USER 9653:9653
ENTRYPOINT ./entrypoint.sh

FROM python:3.9-alpine AS python3-9
RUN mkdir /.cache /.local
ADD runtimes/python3-9 /workspace
RUN chown -R 9653 /.cache /.local /workspace
WORKDIR /workspace
USER 9653:9653
ENTRYPOINT ./entrypoint.sh
