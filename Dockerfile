# Build the manager binary
FROM mirror.gcr.io/library/golang:1.21 AS builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY controllers/ controllers/
COPY pkg/ pkg/

# Build
ARG GIT_SHA
ARG DIRTY
ARG VERSION

ENV GIT_SHA=${GIT_SHA:-unknown}
ENV DIRTY=${DIRTY:-unknown}
ENV VERSION=${VERSION:-unknown}

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -ldflags "-X main.version=${VERSION} -X main.gitSHA=${GIT_SHA} -X main.dirty=${DIRTY}" -o manager main.go

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=builder /workspace/manager .
USER 65532:65532

# Quay image expiry
ARG QUAY_IMAGE_EXPIRY=never
LABEL quay.expires-after=$QUAY_IMAGE_EXPIRY

ENTRYPOINT ["/manager"]
