FROM bearstech/java:1.8

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-transport-https \
    && wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - \
    && echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" > /etc/apt/sources.list.d/elastic.list \
    && rm -rf /var/lib/apt/lists/*

RUN adduser --uid 1001 --system elasticsearch

ENV ELASTICSEARCH_VERSION=6.7.1
RUN apt-get update \
    && apt-get install -y --no-install-recommends elasticsearch=${ELASTICSEARCH_VERSION} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 9200
LABEL traefik.port=9200
EXPOSE 9300
VOLUME /var/lib/elasticsearch
VOLUME /var/log/elasticsearch

COPY elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
RUN chown -R elasticsearch /etc/default/elasticsearch /etc/elasticsearch/ \
    && chmod 400 /etc/default/elasticsearch /etc/elasticsearch/elasticsearch.yml
USER elasticsearch
ENV CLUSTER_NAME=docker
ARG GIT_VERSION
LABEL com.bearstech.source.elastic=https://github.com/factorysh/docker-elastic/commit/${GIT_VERSION}

CMD ["/usr/share/elasticsearch/bin/elasticsearch"]
