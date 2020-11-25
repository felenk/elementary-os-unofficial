export BASE_IMAGE=ubuntu:18.04
export SHELL=/bin/bash

.PHONY: qemu wrap build-userland build build-onbuild push manifest clean

clean:
	-docker rm -v $$(docker ps -a -q -f status=exited)
	-docker rmi $$(docker images -q -f dangling=true)
	-docker rmi $$(docker images --format '{{.Repository}}:{{.Tag}}' | grep '$(IMAGE_NAME)')

image:
	mkdir -p artifacts
	docker run --privileged -i \
        -v /proc:/proc \
        -v ${PWD}/artifacts:/artifacts \
        -v ${PWD}:/working_dir \
        -w /working_dir \
        debian:latest \
        ./build.sh
