FROM ubuntu:16.04
MAINTAINER = Di Xu <stephenhsu90@gmail.com>

EXPOSE 5000 35357
ENV KEYSTONE_VERSION 9.1.0
ENV KEYSTONE_ADMIN_PASSWORD passw0rd
ENV KEYSTONE_DB_ROOT_PASSWD passw0rd
ENV KEYSTONE_DB_PASSWD passw0rd
ENV KEYSTONE_TOKEN_EXPRIATION_TIME 600
ENV KEYSTONE_DB_PORT 3306

LABEL version="$KEYSTONE_VERSION"
LABEL description="Openstack Keystone Docker Image Supporting HTTP/HTTPS"

RUN apt-get -y update \
    && apt-get install -y apache2 libapache2-mod-wsgi git memcached\
        libffi-dev python-dev libssl-dev mysql-client libldap2-dev libsasl2-dev\
    && apt-get -y clean

RUN apt-get install -y software-properties-common
RUN add-apt-repository cloud-archive:ocata
RUN apt-get -y update && apt-get -y dist-upgrade
RUN apt-get install -y python-openstackclient
RUN apt-get install -y keystone

RUN rm /etc/keystone/keystone.conf
COPY /etc/keystone.conf /etc/keystone/keystone.conf

COPY keystone.sql /keystone.sql
COPY bootstrap.sh /bootstrap.sh

WORKDIR /root
CMD sh -x /bootstrap.sh
