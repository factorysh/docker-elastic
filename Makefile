
include Makefile.lint
include Makefile.build_args

GOSS_VERSION := 0.3.7
VERSION6 := 6.8.22
VERSION7 := 7.10.2
CEREBRO_VERSION := 0.9.4

build: build6 build7 build-cerebro

build6: build-elasticsearch6 build-logstash6 build-kibana6
build7: build-elasticsearch7 build-logstash7 build-kibana7

build-elastic6:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg ELASTIC_MAJOR=6 \
		-t bearstech/elastic:6 \
		-f Dockerfile.elastic \
		.

build-elastic7:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg ELASTIC_MAJOR=7 \
		-t bearstech/elastic:7 \
		-f Dockerfile.elastic \
		.

build-elastic6-java:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg ELASTIC_MAJOR=6 \
		-t bearstech/elastic-java:6 \
		-f Dockerfile.elastic-java \
		.

build-elastic7-java:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg ELASTIC_MAJOR=7 \
		-t bearstech/elastic-java:7 \
		-f Dockerfile.elastic-java \
		.

build-elasticsearch6: build-elastic6-java
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg ELASTIC_MAJOR=6 \
		--build-arg ELASTICSEARCH_VERSION=${VERSION6} \
		-t bearstech/elasticsearch:6 \
		-f Dockerfile.elasticsearch \
		.

build-elasticsearch7: build-elastic7-java
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg ELASTIC_MAJOR=7 \
		--build-arg ELASTICSEARCH_VERSION=${VERSION7} \
		-t bearstech/elasticsearch:7 \
		-f Dockerfile.elasticsearch \
		.
	docker tag bearstech/elasticsearch:7 bearstech/elasticsearch:latest

build-cerebro:
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg CEREBRO_VERSION=${CEREBRO_VERSION} \
		-t bearstech/cerebro \
		-f Dockerfile.cerebro \
		.

build-logstash6: build-elastic6-java
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg ELASTIC_MAJOR=6 \
		--build-arg LOGSTASH_VERSION=1:${VERSION6}-1 \
		-t bearstech/logstash:6 \
		-f Dockerfile.logstash \
		.

build-logstash7: build-elastic7-java
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg ELASTIC_MAJOR=7 \
		--build-arg LOGSTASH_VERSION=1:${VERSION7}-1 \
		-t bearstech/logstash:7 \
		-f Dockerfile.logstash \
		.
	docker tag bearstech/logstash:7 bearstech/logstash:latest

build-kibana6: build-elastic6
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg ELASTIC_MAJOR=6 \
		--build-arg KIBANA_VERSION=${VERSION6} \
		-t bearstech/kibana:6 \
		-f Dockerfile.kibana \
		.

build-kibana7: build-elastic7
	 docker build \
		$(DOCKER_BUILD_ARGS) \
		--build-arg ELASTIC_MAJOR=7 \
		--build-arg KIBANA_VERSION=${VERSION7} \
		-t bearstech/kibana:7 \
		-f Dockerfile.kibana \
		.
	docker tag bearstech/kibana:6 bearstech/kibana:latest

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

data/kibana:
	mkdir -p data/kibana

push: push6 push7
	docker push bearstech/cerebro

push6:
	docker push bearstech/elasticsearch:6
	docker push bearstech/logstash:6
	docker push bearstech/kibana:6

push7:
	docker push bearstech/elasticsearch:7
	docker push bearstech/elasticsearch:latest
	docker push bearstech/logstash:7
	docker push bearstech/logstash:latest
	docker push bearstech/kibana:7
	docker push bearstech/kibana:latest

up: .env
	ELASTIC_MAJOR=7 docker-compose up \
		--remove-orphans \
		--detach \
	kibana cerebro

.env:
	echo "UID=`id -u`\n" > .env

test-elasticsearch6: bin/wait-for bin/goss .env
	docker-compose down
	rm -rf data/elasticsearch
	mkdir -p data/elasticsearch/{lib,log}
	docker run \
		--rm \
		-v `pwd`/bin/goss:/usr/local/bin/goss:ro \
		-v `pwd`/tests:/tests:ro \
		-w /tests \
		bearstech/elasticsearch:6 \
		goss --vars=vars6.yml -g elasticsearch.yml validate
	ELASTIC_MAJOR=6 docker-compose up client_es
	docker-compose down

test-elasticsearch7: bin/wait-for bin/goss .env
	docker-compose down
	rm -rf data/elasticsearch
	mkdir -p data/elasticsearch/{lib,log}
	docker run \
		--rm \
		-v `pwd`/bin/goss:/usr/local/bin/goss:ro \
		-v `pwd`/tests:/tests:ro \
		-w /tests \
		bearstech/elasticsearch:7 \
		goss --vars=vars7.yml -g elasticsearch.yml validate
	ELASTIC_MAJOR=7 docker-compose up client_es
	docker-compose down

test-cerebro6: bin/wait-for data/cerebro data/kibana .env
	docker-compose down
	rm -rf data/elasticsearch
	rm -rf data/cerebro
	mkdir -p data/elasticsearch/{lib,log}
	mkdir -p data/cerebro
	chmod 777 data/cerebro
	ELASTIC_MAJOR=6 docker-compose up -d cerebro
	ELASTIC_MAJOR=6 docker-compose up --exit-code-from client client
	docker-compose down

test-cerebro7: bin/wait-for data/cerebro data/kibana .env
	docker-compose down
	rm -rf data/elasticsearch
	rm -rf data/cerebro
	mkdir -p data/elasticsearch/{lib,log}
	mkdir -p data/cerebro
	chmod 777 data/cerebro
	ELASTIC_MAJOR=7 docker-compose up -d cerebro
	ELASTIC_MAJOR=7 docker-compose up --exit-code-from client client
	docker-compose down

test-logstash6: bin/goss
	docker run \
		--rm \
		-v `pwd`/bin/goss:/usr/local/bin/goss:ro \
		-v `pwd`/tests:/tests:ro \
		-w /tests \
		bearstech/logstash:6 \
		goss --vars=vars6.yml -g logstash.yml validate

test-logstash7: bin/goss
	docker run \
		--rm \
		-v `pwd`/bin/goss:/usr/local/bin/goss:ro \
		-v `pwd`/tests:/tests:ro \
		-w /tests \
		bearstech/logstash:7 \
		goss --vars=vars7.yml -g logstash.yml validate

tests: tests6 tests7
tests6: test-elasticsearch6 test-logstash6 test-cerebro6
tests7: test-elasticsearch7 test-logstash7 test-cerebro7

down:
	@echo "ok"

clean:
	rm -rf data bin
