#!/bin/sh

set -e

echo "$@"

# Drop root privileges if we are running elasticsearch
if [ "$1" = '/usr/share/elasticsearch/bin/elasticsearch' ]; then
    echo "Elasticsearch"
    usermod -o -u "$ID" elasticsearch
    chown -R elasticsearch /etc/default/elasticsearch /etc/elasticsearch/ /var/log/elasticsearch /var/lib/elasticsearch
    exec gosu elasticsearch "$@"
else
    # As argument is not related to elasticsearch,
    # then assume that user wants to run his own process,
    # for example a `bash` shell to explore this image
    exec "$@"
fi

