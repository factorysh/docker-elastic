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

bin:
	mkdir -p bin

bin/goss: bin
	curl -o bin/goss -L https://github.com/aelsabbahy/goss/releases/download/v${GOSS_VERSION}/goss-linux-amd64
	chmod +x bin/goss

bin/wait-for: bin
	curl -o bin/wait-for https://raw.githubusercontent.com/eficode/wait-for/master/wait-for
	chmod +x bin/wait-for

data/cerebro:
	mkdir -p data/cerebro

data/elasticsearch/lib:
	mkdir -p data/elasticsearch/lib

data/elasticsearch/log:
	mkdir -p data/elasticsearch/log

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

test-cerebro: bin/wait-for data/cerebro data/elasticsearch/lib data/elasticsearch/log
	docker-compose down
	docker-compose up -d cerebro
	docker-compose up --exit-code-from client
	docker-compose down

tests: test-cli test-cerebro

down:
	@echo "ok"

clean:
	rm -rf data
