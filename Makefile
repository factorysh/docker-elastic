GOSS_VERSION := 0.3.6
GIT_VERSION := $(shell git rev-parse HEAD)

build: build-es build-cerebro

build-es:
	docker build \
		--build-arg GIT_VERSION=${GIT_VERSION} \
		-t bearstech/elasticsearch:6 \
		.
	docker tag bearstech/elasticsearch:6 bearstech/elasticsearch:latest

build-cerebro:
	docker build \
		-t bearstech/cerebro \
		--build-arg GIT_VERSION=${GIT_VERSION} \
		-f Dockerfile.cerebro \
		.

pull:
	docker pull bearstech/java:latest

bin/goss:
	mkdir -p bin
	curl -o bin/goss -L https://github.com/aelsabbahy/goss/releases/download/v${GOSS_VERSION}/goss-linux-amd64
	chmod +x bin/goss

push:
	docker push bearstech/elasticsearch:6
	docker push bearstech/elasticsearch:latest
	docker push bearstech/cerebro

up: .env
	docker-compose up

.env:
	echo "UID=`id -u`\n" > .env

test-cli: bin/goss
	docker run \
		--rm \
		-v `pwd`/bin/goss:/usr/local/bin/goss:ro \
		-v `pwd`/tests:/tests:ro \
		-w /tests \
		bearstech/elasticsearch:latest \
		goss --vars=vars.yml validate

test-cerebro:
	docker-compose down
	docker-compose up -d cerebro
	sleep 15
	docker-compose up --exit-code-from client
	docker-compose down

tests: test-cli test-cerebro

down:
	@echo "ok"

clean:
	rm -rf data
