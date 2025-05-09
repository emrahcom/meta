OS=$(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(shell uname -m)
ifeq ($(ARCH),x86_64)
	ARCH=amd64
	ARCH_SHCK=x86_64
else ifeq ($(ARCH),arm64)
	ARCH=arm64
	ARCH_SHCK=arm64
else ifeq ($(ARCH),aarch64)
	ARCH=arm64
	ARCH_SHCK=arm64
else ifeq ($(ARCH),i386)
	ARCH=386
	ARCH_SHCK=386
else ifeq ($(ARCH),i686)
	ARCH=386
	ARCH_SHCK=386
endif

format: .bin/ory .bin/shfmt node_modules  # formats the source code
	echo formatting ...
	.bin/ory dev headers copyright --type=open-source
	.bin/shfmt --write .
	npm exec -- prettier --write .

help:  # shows all available Make commands
	cat Makefile | grep '^[^ ]*:' | grep -v '^\.bin/' | grep -v '^node_modules' | grep -v '.SILENT:' | grep -v help | sed 's/:.*#/#/' | column -s "#" -t

licenses: .bin/licenses node_modules  # checks open-source licenses
	.bin/licenses

.bin/licenses: Makefile
	curl https://raw.githubusercontent.com/ory/ci/master/licenses/install | sh

test: .bin/shellcheck .bin/shfmt node_modules  # runs all linters
	echo running tests ...
	find . -name '*.sh' | xargs .bin/shellcheck
	echo Verifying formatting ...
	.bin/shfmt --list .

.bin/ory: Makefile
	echo installing Ory CLI ...
	curl https://raw.githubusercontent.com/ory/meta/master/install.sh | bash -s -- -b .bin ory v1.1.0
	touch .bin/ory

.bin/shellcheck: Makefile
	echo installing Shellcheck ...
	mkdir -p .bin
	if [ "$$(uname -s)" = "Darwin" ] && [ "$$(uname -m)" = "arm64" ]; then \
		echo " - detected macOS ARM64" && \
		curl -sSL https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.darwin.aarch64.tar.xz | tar xJ; \
	elif [ "$$(uname -s)" = "Linux" ] && [ "$$(uname -m)" = "x86_64" ]; then \
		echo " - detected Linux AMD64" && \
		curl -sSL https://github.com/koalaman/shellcheck/releases/download/v0.10.0/shellcheck-v0.10.0.linux.x86_64.tar.xz | tar xJ; \
	else \
		echo " - unsupported architecture: $$(uname -s) $$(uname -m)" && \
		exit 1; \
	fi
	mv shellcheck-v0.10.0/shellcheck .bin
	rm -rf shellcheck-v0.10.0
	touch .bin/shellcheck

.bin/shfmt: Makefile
	mkdir -p .bin
	curl -sSL https://github.com/mvdan/sh/releases/download/v3.10.0/shfmt_v3.10.0_$(OS)_$(ARCH) -o .bin/shfmt
	chmod +x .bin/shfmt

node_modules: package.json package-lock.json
	echo installing Node dependencies ...
	npm ci
	touch node_modules  # update timestamp so that Make doesn't reinstall it over and over


.SILENT:
.DEFAULT_GOAL := help
