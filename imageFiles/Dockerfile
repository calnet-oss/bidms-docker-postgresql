#
# Copyright (c) 2017, Regents of the University of California and
# contributors.
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
# PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# 
FROM bidms/debian_base

ARG APT_PROXY_URL=
RUN if [ ! -z "$APT_PROXY_URL" ]; then echo "Acquire::http::Proxy \"$APT_PROXY_URL\";" > /etc/apt/apt.conf.d/00aptproxy; else echo "not using apt proxy"; fi

ARG POSTGRESQL_VERSION=9.6

RUN set -x \
  && export DEBIAN_FRONTEND=noninteractive \
  && echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
  && apt-get install -y gnupg2 \
  && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - \
  && apt-get purge -y gnupg2 \
  && apt-get update \
  && apt-get dist-upgrade -y \
  && apt-get install -y postgresql-${POSTGRESQL_VERSION} \
       postgresql-client-${POSTGRESQL_VERSION} \
       postgresql-contrib-${POSTGRESQL_VERSION} \
       openssl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /core

COPY root/ /root/
COPY tmp_passwords/ /tmp/tmp_passwords/
RUN chown postgres:postgres /tmp/tmp_passwords/postgres_pw

# We're not interested in the initial PostgreSQL data files created during
# the installation of the PostgreSQL packages, so we delete the data
# directory and start over.
ARG POSTGRESQL_LOCALE=en_US.UTF-8
RUN /etc/init.d/postgresql stop \
  && rm -rf /var/lib/postgresql/${POSTGRESQL_VERSION}/main/* \
  && sudo -u postgres \
       /usr/lib/postgresql/${POSTGRESQL_VERSION}/bin/initdb \
       --encoding=UTF8 --locale=$POSTGRESQL_LOCALE \
       -D /var/lib/postgresql/${POSTGRESQL_VERSION}/main \
       --pwfile=/tmp/tmp_passwords/postgres_pw --auth=md5 \
  && echo -n "localhost:5432:*:postgres:" > /var/lib/postgresql/.pgpass \
  && chmod 600 /var/lib/postgresql/.pgpass \
  && cat /tmp/tmp_passwords/postgres_pw >> /var/lib/postgresql/.pgpass \
  && chown postgres:postgres /var/lib/postgresql/.pgpass \
  && mv /var/lib/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf /var/lib/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf.ORIG.${POSTGRESQL_VERSION} \
  && mv /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_hba.conf /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_hba.conf.ORIG.${POSTGRESQL_VERSION}

COPY postgresql_main/ /var/lib/postgresql/${POSTGRESQL_VERSION}/main/

# Generate a self-signed key pair for TLS
RUN echo "temporary" > /tmp/tmp_passwords/tls_key_passphrase \
  && chmod 600 /tmp/tmp_passwords/tls_key_passphrase \
  && mkdir /var/lib/postgresql/certs \
  && openssl req -x509 -newkey rsa:4096 -days 10000 \
       -keyout /tmp/tmp_passwords/tmp_privkey.pem \
       -out /var/lib/postgresql/certs/pubkey.pem \
       -subj "/OU=BIDMS PostgreSQL Docker Dev/CN=localhost" \
       -passout file:/tmp/tmp_passwords/tls_key_passphrase \
  && openssl rsa -in /tmp/tmp_passwords/tmp_privkey.pem \
       -out /var/lib/postgresql/certs/privkey.pem \
       -passin file:/tmp/tmp_passwords/tls_key_passphrase \
  && chmod 600 /var/lib/postgresql/certs/privkey.pem \
  && chown postgres:postgres /var/lib/postgresql/certs/* \
  && rm -f /tmp/tmp_passwords/tls_key_passphrase \
       /tmp/tmp_passwords/tmp_privkey.pem

RUN rm -rf /tmp/tmp_passwords

EXPOSE 5432

COPY etc/container/ /etc/container/
ENTRYPOINT ["/etc/container/postgresql-entrypoint.sh", "interactive"]

# Use 'docker inspect <name>' to find the volume files on the host.
# <name> is the value of the --name parameter when invoking docker run.
VOLUME /var/lib/postgresql
