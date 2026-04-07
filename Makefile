IMAGE := venatum/earnapp
BUILD_CTX := build

.PHONY: build-app build-debian build-lite build-all run-app run-debian run-lite clean

build-app:
	docker build -f $(BUILD_CTX)/app/Dockerfile $(BUILD_CTX) -t $(IMAGE):latest

build-debian:
	docker build -f $(BUILD_CTX)/debian/Dockerfile $(BUILD_CTX) -t $(IMAGE):debian

build-lite:
	docker build -f $(BUILD_CTX)/lite/Dockerfile $(BUILD_CTX) -t $(IMAGE):lite

build-all: build-app build-debian build-lite

run-app:
	docker run -d --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v $(HOME)/earnapp-data:/etc/earnapp --name earnapp $(IMAGE):latest

run-debian:
	docker run -d --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v $(HOME)/earnapp-data:/etc/earnapp --name earnapp $(IMAGE):debian

run-lite:
	@test -n "$(UUID)" || (echo "Usage: make run-lite UUID=sdk-node-xxx" && exit 1)
	docker run -d -e EARNAPP_UUID='$(UUID)' --name earnapp $(IMAGE):lite

clean:
	-docker rm -f earnapp
