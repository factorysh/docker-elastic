GOSS_VERSION := 0.3.6

build:
	docker build -t bearstech/elasticsearch:6 .
	docker tag bearstech/elasticsearch:6 bearstech/elasticsearch:latest

pull:
	docker pull bearstech/java:latest

bin/goss:
	mkdir -p bin
	curl -o bin/goss -L https://github.com/aelsabbahy/goss/releases/download/v${GOSS_VERSION}/goss-linux-amd64
	chmod +x bin/goss

