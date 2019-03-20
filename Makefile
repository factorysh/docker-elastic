GOSS_VERSION := 0.3.6

build: build-es build-cerebro

build-es:
	docker build -t bearstech/elasticsearch:6 .
	docker tag bearstech/elasticsearch:6 bearstech/elasticsearch:latest

build-cerebro:
	docker build -t bearstech/cerebro -f Dockerfile.cerebro .

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

tests:
	@echo "ok"

down:
	@echo "ok"

clean:
	rm -rf data
