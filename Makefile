export GO111MODULE = on
OSTYPE := $(shell uname -s | tr '[A-Z]' '[a-z]')

# Go build flags
ifeq ($(GOOS),)
ifeq ($(OSTYPE), darwin)
	GOOS := darwin
else
	GOOS := linux
endif
endif

build:
	CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) go build
	./kcfishgen > completions/kubectl.fish
