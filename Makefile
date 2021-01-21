ifeq ($(OS),Windows_NT)
	ifeq ($(PROCESSOR_ARCHITECTURE),AMD64)
		ARCH=amd64
		OS=windows
	endif
else
	UNAME_S := $(shell uname -s)
	ifeq ($(UNAME_S),Linux)
		OS=linux
		ARCH=amd64
	endif
	ifeq ($(UNAME_S),Darwin)
		OS=darwin
		ARCH=amd64
	endif
endif

BINARY_DEPENDENCIES		= kubectl2 yq2

define get-binary-dependency
.bin/$(1): .deps/$(1).yaml
		URL=$(${CURDIR}/ory dev ci deps url -o ${OS} -a ${ARCH} -c .deps/$(1).yaml); \
		echo "Downloading '$(1)' $${URL}...."; \
		curl -Lo .bin/$(1) $${URL}; \
		chmod +x .bin/$(1);
endef

$(foreach dep,$(BINARY_DEPENDENCIES),$(eval $(call get-binary-dependency,$(dep))))

SHELL=/bin/bash -o pipefail

.PHONY: deps test list deps-working test test-gen

.bin/yq: .deps/yq.yaml
		@URL=$$(./ory dev ci deps url -o ${OS} -a ${ARCH} -c .deps/yq.yaml); \
		echo "Downloading 'yq' $${URL}...."; \
		curl -Lo .bin/yq $${URL}; \
		chmod +x .bin/yq;

.bin/kubectl: .deps/kubectl.yaml
		@URL=$$(./ory dev ci deps url -o ${OS} -a ${ARCH} -c .deps/kubectl.yaml); \
		echo "Downloading 'kubectl' $${URL}...."; \
		curl -Lo .bin/kubectl $${URL}; \
		chmod +x .bin/kubectl;

.bin/trivy: .deps/trivy.yaml
		@URL=$$(./ory dev ci deps url -o ${OS} -a ${ARCH} -c .deps/trivy.yaml); \
		echo "Downloading 'trivy' $${URL}...."; \
		curl -L $${URL} | tar -xmz -C .bin trivy; \
		chmod +x .bin/trivy;


deps: .bin/yq .bin/kubectl .bin/trivy
		@echo "Dependencies downloaded / updated."

deps-working: .bin/yq .bin/kubectl
		@echo "Dependencies downloaded / updated (without trivy, as Make always downloads it :("

test: 
		./ory dev ci deps url -o ${OS} -a ${ARCH} -c .deps/yq.yaml
		./ory dev ci deps url -o ${OS} -a ${ARCH} -c .deps/kubectl.yaml
		./ory dev ci deps url -o ${OS} -a ${ARCH} -c .deps/trivy.yaml

test-gen: list .bin/kubectl2
		
list:
		@grep '^[^#[:space:]].*:' Makefile