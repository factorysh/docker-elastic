FROM bearstech/java:latest

RUN apt-get update \
    && apt-get install -y apt-transport-https \
    && wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - \
    && echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" > /etc/apt/sources.list.d/elastic.list \
    && apt-get update \
    && apt-get install elasticsearch \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

