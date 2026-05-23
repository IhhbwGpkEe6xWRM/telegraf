# Makefile for telegraf
# Fork of influxdata/telegraf

PLATFORM ?= linux
ARCH ?= amd64
GOOS ?= $(PLATFORM)
GOARCH ?= $(ARCH)

VERSION ?= $(shell git describe --exact-match --tags 2>/dev/null || echo "unknown")
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

GO_BUILD_FLAGS = -ldflags \
	"-X main.version=$(VERSION) \
	-X main.commit=$(COMMIT) \
	-X main.branch=$(BRANCH) \
	-X main.buildDate=$(BUILD_DATE)"

BINARY = telegraf
BIN_DIR = bin

.PHONY: all build clean test lint fmt vet deps install

all: build

## build: Compile the binary
build:
	@echo "Building $(BINARY) version=$(VERSION) commit=$(COMMIT)"
	@mkdir -p $(BIN_DIR)
	GOOS=$(GOOS) GOARCH=$(GOARCH) go build $(GO_BUILD_FLAGS) -o $(BIN_DIR)/$(BINARY) ./cmd/telegraf

## install: Install the binary to GOPATH/bin
install:
	@echo "Installing $(BINARY)..."
	go install $(GO_BUILD_FLAGS) ./cmd/telegraf

## test: Run unit tests
test:
	@echo "Running tests..."
	go test -v -race -timeout 120s ./...

## test-short: Run short unit tests
test-short:
	@echo "Running short tests..."
	go test -short -timeout 60s ./...

## lint: Run golangci-lint
lint:
	@echo "Running linter..."
	golangci-lint run ./...

## fmt: Format Go source files
fmt:
	@echo "Formatting source files..."
	gofmt -s -w $$(find . -name '*.go' -not -path './vendor/*')

## vet: Run go vet
vet:
	@echo "Running go vet..."
	go vet ./...

## deps: Download and tidy dependencies
deps:
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BIN_DIR)

## docker: Build docker image
docker:
	@echo "Building Docker image..."
	docker build -t telegraf:$(VERSION) .

## help: Display available make targets
help:
	@echo "Available targets:"
	@grep -E '^## ' Makefile | sed 's/^## /  /'

## run: Build and run telegraf with a local config for quick testing
# Usage: make run CONFIG=./testdata/telegraf.conf
CONFIG ?= ./etc/telegraf.conf
run: build
	@echo "Running $(BINARY) with config $(CONFIG)"
	$(BIN_DIR)/$(BINARY) --config $(CONFIG)
