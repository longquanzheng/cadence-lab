PROJECT_ROOT = example.com/cadence-sqlite

export PATH := $(shell go env GOPATH)/bin:$(PATH)

default: bins

ifndef GOOS
GOOS := $(shell go env GOOS)
endif

ifndef GOARCH
GOARCH := $(shell go env GOARCH)
endif

# Automatically gather all srcs
ALL_SRC := $(shell find . -name "*.go" | grep -v -e Godeps -e vendor \
	-e ".*/\..*" \
	-e ".*/_.*" \
	-e ".*/mocks.*")

cadence-sql-tool: $(ALL_SRC)
	@echo "compiling cadence-sql-tool with OS: $(GOOS), ARCH: $(GOARCH)"
	go build -i -o cadence-sql-tool cmd/sql-tool/main.go

cadence-server: $(ALL_SRC)
	@echo "compiling cadence-server with OS: $(GOOS), ARCH: $(GOARCH)"
	go build -ldflags '$(GO_BUILD_LDFLAGS)' -i -o cadence-server cmd/server/main.go

lint:
	@echo "running linter"
	@lintFail=0; for file in $(ALL_SRC); do \
		golint "$$file"; \
		if [ $$? -eq 1 ]; then lintFail=1; fi; \
	done; \
	if [ $$lintFail -eq 1 ]; then exit 1; fi;
	@OUTPUT=`gofmt -l $(ALL_SRC) 2>&1`; \
	if [ "$$OUTPUT" ]; then \
		echo "Run 'make fmt'. gofmt must be run on the following files:"; \
		echo "$$OUTPUT"; \
		exit 1; \
	fi

fmt:
	GO111MODULE=off go get -u github.com/myitcv/gobin
	GOOS= GOARCH= gobin -mod=readonly golang.org/x/tools/cmd/goimports
	@echo "running goimports"
	@goimports -local "github.com/uber/cadence" -w $(ALL_SRC)

install-schema-sqlite: cadence-sql-tool
	./cadence-sql-tool --pl sqlite create --db cadence.db
	./cadence-sql-tool --pl sqlite --db cadence.db setup -v 0.0
	./cadence-sql-tool --pl sqlite --db cadence.db update-schema -d ./sqlite-schema/cadence/versioned
	./cadence-sql-tool --pl sqlite create --db cadence_visibility.db
	./cadence-sql-tool --pl sqlite --db cadence_visibility.db setup-schema -v 0.0
	./cadence-sql-tool --pl sqlite --db cadence_visibility.db update-schema -d ./sqlite-schema/visibility/versioned

bins: cadence-server cadence-sql-tool

clean:
	rm -f cadence.db
	rm -f cadence_visibility.db
	rm -f cadence-sql-tool
	rm -f cadence-server