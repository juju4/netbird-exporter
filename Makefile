.PHONY: build test clean docker

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOMOD=$(GOCMD) mod
BINARY_NAME=netbird-exporter
DOCKER_TAG=gocloudio/netbird-exporter:latest
# Packages parameters
DIST_DIR      ?= dist/
ARCH          ?= $(shell uname -m)
VERSION       ?= $(shell git describe --abbrev --long HEAD)
ABBREV        ?= $(shell git rev-parse --short HEAD)
COMMIT        ?= $(shell git rev-parse HEAD)
TAG           ?= $(shell git describe --tags --abbrev=0 HEAD)
VERSION_PKG   ?= $(shell echo $(VERSION) | sed 's/^v//g')
LICENSE       := MIT
URL           := https://github.com/gocloudio/netbird-exporter
DESCRIPTION   := A Prometheus exporter for NetBird peer metrics.
DATE          :=  $(shell date +%FT%T%z)
MAINTAINER    := dkrhodes@users.noreply.github.com

all: test build

build:
	$(GOBUILD) -o $(BINARY_NAME) -v ./cmd/netbird-exporter

test:
	$(GOTEST) -v ./...

.PHONY: prepare
prepare:
	mkdir -p $(DIST_DIR)

clean:
	$(GOCLEAN)
	rm -f $(BINARY_NAME)

docker:
	docker build -t $(DOCKER_TAG) .

run:
	./$(BINARY_NAME)

tidy:
	$(GOMOD) tidy

# Cross-compilation
build-linux:
	mkdir -p output
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -o output/$(BINARY_NAME)-linux-amd64 -v ./cmd/netbird-exporter

build-arm:
	mkdir -p output	
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 $(GOBUILD) -o output/$(BINARY_NAME)-linux-arm64 -v ./cmd/netbird-exporter

.PHONY: package-deb
package-deb: prepare
	fpm -s dir -t deb -n $(BINARY_NAME) -v $(VERSION_PKG) \
        --maintainer "$(MAINTAINER)" \
        --description "$(DESCRIPTION)"  \
        --url "$(URL)" \
        --architecture $(ARCH) \
        --license "$(LICENSE)" \
        --package $(DIST_DIR) \
        $(OUTPUT)=/usr/local/bin/netbird-exporter \
        package/netbird-exporter.service=/lib/systemd/system/netbird-exporter.service

.PHONY: package-rpm
package-rpm: prepare
	fpm -s dir -t rpm -n $(BINARY_NAME) -v $(VERSION_PKG) \
        --maintainer "$(MAINTAINER)" \
        --description "$(DESCRIPTION)" \
        --url "$(URL)" \
        --architecture $(ARCH) \
        --license "$(LICENSE) "\
        --package $(DIST_DIR) \
        $(OUTPUT)=/usr/local/bin/netbird-exporter \
        package/netbird-exporter.service=/lib/systemd/system/netbird-exporter.service
