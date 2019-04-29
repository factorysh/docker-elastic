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

build-logstash:
	docker build \
		--build-arg GIT_VERSION=${GIT_VERSION} \
		-t bearstech/logstash:6 \
		-f Dockerfile.logstash \
		.
	docker tag bearstech/logstash:6 bearstech/logstash:latest

pull:
	docker pull bearstech/java:latest

bin:
	mkdir -p bin

bin/goss: bin
	curl -o bin/goss -L https://github.com/aelsabbahy/goss/releases/download/v${GOSS_VERSION}/goss-linux-amd64
	chmod +x bin/goss

bin/wait-for: bin
	curl -o bin/wait-for https://raw.githubusercontent.com/factorysh/wait-for/master/wait-for
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
	docker push bearstech/logstash:6
	docker push bearstech/logstash:latest

up: .env
	docker-compose up

.env:
	echo "UID=`id -u`\n" > .env

test-elasticsearch: bin/goss
	docker run \
		--rm \
		-v `pwd`/bin/goss:/usr/local/bin/goss:ro \
		-v `pwd`/tests:/tests:ro \
		-w /tests \
		bearstech/elasticsearch:latest \
		goss --vars=vars.yml -g elasticsearch.yml validate

test-cerebro: bin/wait-for data/cerebro data/elasticsearch/lib data/elasticsearch/log
	docker-compose down
	docker-compose up -d cerebro
	docker-compose up --exit-code-from client
	docker-compose down

test-logstash: bin/goss
	docker run \
		--rm \
		-v `pwd`/bin/goss:/usr/local/bin/goss:ro \
		-v `pwd`/tests:/tests:ro \
		-w /tests \
		bearstech/logstash:latest \
		goss --vars=vars.yml -g logstash.yml validate

tests: test-elasticsearch test-cerebro test-logstash

down:
	@echo "ok"

clean:
	rm -rf data bin
