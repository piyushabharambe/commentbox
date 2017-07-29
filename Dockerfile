# Version 1.0.0
FROM ubuntu:trusty
MAINTAINER James Bugara "bugara.james@yahoo.com"
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
RUN apt-get update && apt-get autoremove && apt-get install -y nodejs && apt-get install -y supervisor
VOLUME ["/data/db"]
VOLUME ["/var/log/supervisord"]
VOLUME ["/var/log/merncomment"]
#VOLUME ["/opt/workspace/merncomment"]
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN dpkg-divert --local --rename --add /etc/init.d/mongod
RUN ln -s /bin/true /etc/init.d/mongod
RUN \
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 && \
echo 'deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse' > /etc/apt/sources.list.d/mongodb.list && \
apt-get update && \
apt-get install -yq mongodb-org

# use changes to package.json to force Docker not to use the cache
# when we change our application's nodejs dependencies:
ADD package.json /tmp/package.json
RUN cd /tmp && npm install
RUN mkdir -p /opt/workspace/merncomment && cp -a /tmp/node_modules /opt/workspace/merncomment/

# From here we load our application's code in, therefore the previous docker
# "layer" thats been cached will be used if possible
WORKDIR /opt/workspace/merncomment
ADD . /opt/workspace/merncomment

RUN npm install
EXPOSE 3000 3001 27017
ENTRYPOINT ["/usr/bin/supervisord", "-c", "/opt/workspace/merncomment/supervisord.conf"]
