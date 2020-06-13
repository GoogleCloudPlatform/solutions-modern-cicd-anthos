PKGS := $(shell go list ./... | grep -v /vendor)

.PHONY: test
test:
	go test $(PKGS)

BIN_DIR := $(GOPATH)/bin
BINARY := anthos-platform-cli
VERSION ?= vlatest
PLATFORMS := windows linux darwin
os = $(word 1, $@)

$(eval GIT_COMMIT=$(shell sh -c "git rev-parse --short HEAD"))

.PHONY: $(PLATFORMS)
$(PLATFORMS):
		mkdir -p release
		GOOS=$(os) GOARCH=amd64 go build -o release/$(BINARY)-$(VERSION)-$(os)-amd64 -ldflags "-X main.VersionNumber=$(GIT_COMMIT) -X main.Binary=${BINARY}"

.PHONY: release
release: windows linux darwin
