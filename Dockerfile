#############################################
# Build
#############################################
FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS build

RUN apk upgrade --no-cache --force
RUN apk add --update build-base make git

WORKDIR /go/src/github.com/pooley182/go-replace

# Dependencies
COPY go.mod go.sum ./
RUN go mod download

# Compile
COPY . .
RUN make test
ARG TARGETOS TARGETARCH
RUN GOOS=${TARGETOS} GOARCH=${TARGETARCH} make build

#############################################
# Test
#############################################
FROM gcr.io/distroless/static AS test
USER 0:0
WORKDIR /app
COPY --from=build /go/src/github.com/pooley182/go-replace/go-replace .
RUN ["./go-replace", "--help"]

#############################################
# Final
#############################################
FROM alpine
ENV LOG_JSON=1
WORKDIR /
COPY --from=test /app /usr/local/bin
USER 1000:1000
ENTRYPOINT ["go-replace"]
