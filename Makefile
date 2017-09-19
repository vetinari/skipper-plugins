SOURCES            = $(shell find ./tracers -name '*.go' )
TRACERS            = instana basic # lightstep
PLUGINS			   = $(shell for t in $(TRACERS); do echo build/tracing_$$t.so; done )
CURRENT_VERSION    = $(shell git tag | sort -V | tail -n1)
VERSION           ?= $(CURRENT_VERSION)
COMMIT_HASH        = $(shell git rev-parse --short HEAD)

default: plugins

plugins: deps $(PLUGINS) checks

deps:
	go get -t github.com/opentracing/opentracing-go
	glide install
checks: vet fmt tests

tests:
	go test -run LoadPlugin

vet: $(SOURCES)
	go vet $(shell for t in $(TRACERS); do echo ./tracers/$$t/...; done )

fmt: $(SOURCES)
	@if [ "$$(gofmt -d $(SOURCES))" != "" ]; then false; else true; fi

test:
	go test -v

$(PLUGINS): $(SOURCES)
	mkdir -p build/
	MODULE=$(shell basename $@ .so | sed -e 's/tracing_//' ); \
		   go build -buildmode=plugin -o $@ tracers/$$MODULE/$$MODULE.go

clean:
	rm -f build/*.so
