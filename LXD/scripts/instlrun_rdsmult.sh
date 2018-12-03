#! /bin/bash

apt-get update && apt-get install -y build-essential

curl -o /tmp/redis.tar.gz http://download.redis.io/redis-stable.tar.gz \
    && tar zxvf /tmp/redis.tar.gz -C /tmp \
    && make install -C /tmp/redis-stable \
    && mkdir /etc/redis \
    && for p in $(seq 6379 6408);do cp /tmp/redis-stable/redis.conf /etc/redis/redis${p}.conf; sed -i -e "/^port/ s/\([1-9]\{1,\}\)/$p/" -e "/^bind/s/127.0.0.1/0.0.0.0/" /etc/redis/redis${p}.conf; done \
    && rm -rf /tmp/{redis-stable,redis.tar.gz}

apt-get remove -y build-essential \
    && rm -rf /var/lib/apt/lists/*

for p in $(seq 6379 6408); do echo 'start on runlevel [23]' > /etc/init/redis${p}.conf; echo 'stop on runlevel [!23]' >> /etc/init/redis${p}.conf; echo "exec /usr/local/bin/redis-server /etc/redis/redis${p}.conf >>/var/log/redis${p}.log 2>&1" >> /etc/init/redis${p}.conf; sleep 5; start redis${p};done

apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
