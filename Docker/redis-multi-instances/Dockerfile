FROM phusion/baseimage
MAINTAINER richnusgeeks@gmail.com
CMD ["/sbin/my_init"]

RUN apt-get update && apt-get install -y build-essential

RUN curl -o /tmp/redis.tar.gz http://download.redis.io/releases/redis-3.0.5.tar.gz \
    && tar zxvf /tmp/redis.tar.gz -C /tmp \
    && make install -C /tmp/redis-3.0.5 \
    && mkdir /etc/redis \
    && for p in $(seq 6379 6408);do cp /tmp/redis-3.0.5/redis.conf /etc/redis/redis${p}.conf; sed -i "/^port/ s/\([1-9]\{1,\}\)/$p/" /etc/redis/redis${p}.conf; done \
    && rm -rf /tmp/{redis-3.0.5,redis.tar.gz}

RUN apt-get remove -y build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN for p in $(seq 6379 6408); do mkdir /etc/service/redis${p}; echo '#!/bin/sh' > /etc/service/redis${p}/run; echo "exec /usr/local/bin/redis-server /etc/redis/redis${p}.conf >>/var/log/redis${p}.log 2>&1" >> /etc/service/redis${p}/run; chmod +x /etc/service/redis${p}/run; done

EXPOSE 6379 6380 6381 6382 6383 6384 6385 6386 6387 6388 6389 6390 6391 6392 6393 6394 6395 6396 6397 6398 6399 6400 6401 6402 6403 6404 6405 6406 6407 6408

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
