-include env_make

FROM ?= httpd:2.4.35-alpine
VERSION ?= 2.4
TAG ?= $(VERSION)

REPO ?= docksal/apache
NAME ?= docksal-apache-$(VERSION)

BASE_IMAGE_TAG = $(VERSION)

ifneq ($(STABILITY_TAG),)
    ifneq ($(TAG),latest)
        override TAG := $(TAG)-$(STABILITY_TAG)
    endif
endif

.PHONY: build test push shell run start stop logs clean release

default: build

build:
	docker build -t $(REPO):$(TAG) --build-arg FROM=$(FROM) --build-arg VERSION=$(VERSION) .

test:
	IMAGE=$(REPO):$(TAG) REPO=$(REPO) NAME=$(NAME) VERSION=$(VERSION) ../tests/test.bats

push:
	docker push $(REPO):$(TAG)

shell:
	docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run:
	docker run --rm --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) $(CMD)

start:
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	docker rm -f $(NAME)

release: build push
