IMAGE := venatum/earnapp
BUILD_CTX := build
# Optional: fail the build unless BrightData serves this EarnApp version
EARNAPP_VERSION ?=
BUILD := docker build --build-arg EARNAPP_VERSION=$(EARNAPP_VERSION)

.PHONY: build-app build-debian build-lite build-all test-app test-debian test-lite test-all test-registry run-app run-debian run-lite clean

build-app:
	$(BUILD) -f $(BUILD_CTX)/app/Dockerfile $(BUILD_CTX) -t $(IMAGE):latest

build-debian:
	$(BUILD) -f $(BUILD_CTX)/app/Dockerfile --build-arg BASE_IMAGE=debian:trixie-slim $(BUILD_CTX) -t $(IMAGE):debian

build-lite:
	$(BUILD) -f $(BUILD_CTX)/lite/Dockerfile $(BUILD_CTX) -t $(IMAGE):lite

build-all: build-app build-debian build-lite

test-app: build-app
	EXPECTED_VERSION=$(EARNAPP_VERSION) tests/smoke.sh app $(IMAGE):latest

test-debian: build-debian
	EXPECTED_VERSION=$(EARNAPP_VERSION) tests/smoke.sh debian $(IMAGE):debian

test-lite: build-lite
	EXPECTED_VERSION=$(EARNAPP_VERSION) tests/smoke.sh lite $(IMAGE):lite

test-all: test-app test-debian test-lite

# Multi-arch build + push to a private registry, then smoke test the pulled images
# Usage: make test-registry REGISTRY=myhost.local:5000 BUILDER=my-builder [VARIANTS="lite"]
test-registry:
	REGISTRY=$(REGISTRY) BUILDER=$(BUILDER) tests/registry.sh $(VARIANTS)

run-app:
	docker run -d --privileged --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw -v $(HOME)/earnapp-data:/etc/earnapp --name earnapp $(IMAGE):latest

run-debian:
	docker run -d --privileged --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw -v $(HOME)/earnapp-data:/etc/earnapp --name earnapp $(IMAGE):debian

run-lite:
	@test -n "$(UUID)" || (echo "Usage: make run-lite UUID=sdk-node-xxx" && exit 1)
	docker run -d -e EARNAPP_UUID='$(UUID)' --name earnapp $(IMAGE):lite

clean:
	-docker rm -f earnapp
