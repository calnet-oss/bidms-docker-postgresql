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

COPY tmp_passwords/ /tmp/tmp_passwords/
RUN chown postgres:postgres /tmp/tmp_passwords/postgres_pw /tmp/tmp_passwords/registry_pw

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
  && echo "" >> /var/lib/postgresql/.pgpass \
  && chown postgres:postgres /var/lib/postgresql/.pgpass \
  && echo "\nexport PGPASSFILE=/var/lib/postgresql/.pgpass" >> /root/.bashrc \
  && mv /var/lib/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf /var/lib/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf.ORIG.${POSTGRESQL_VERSION} \
  && mv /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_hba.conf /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_hba.conf.ORIG.${POSTGRESQL_VERSION} \
  && mv /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_ident.conf /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_ident.conf.ORIG.${POSTGRESQL_VERSION} \
  && mv /etc/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf /etc/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf.ORIG \
  && mv /etc/postgresql/${POSTGRESQL_VERSION}/main/pg_hba.conf /etc/postgresql/${POSTGRESQL_VERSION}/main/pg_hba.conf.ORIG \
  && mv /etc/postgresql/${POSTGRESQL_VERSION}/main/pg_ident.conf /etc/postgresql/${POSTGRESQL_VERSION}/main/pg_ident.conf.ORIG \
  && cp /etc/postgresql/${POSTGRESQL_VERSION}/main/pg_ident.conf.ORIG /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_ident.conf \
  && ln -fs /var/lib/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf /etc/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf \
  && ln -fs /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_hba.conf /etc/postgresql/${POSTGRESQL_VERSION}/main/pg_hba.conf \
  && ln -fs /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_ident.conf /etc/postgresql/${POSTGRESQL_VERSION}/main/pg_ident.conf

COPY postgresql_main/ /var/lib/postgresql/${POSTGRESQL_VERSION}/main/

RUN chown postgres:postgres /var/lib/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf \
  && chmod 600 /var/lib/postgresql/${POSTGRESQL_VERSION}/main/postgresql.conf \
  && chown postgres:postgres /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_hba.conf \
  && chmod 600 /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_hba.conf \
  && chown postgres:postgres /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_ident.conf \
  && chmod 600 /var/lib/postgresql/${POSTGRESQL_VERSION}/main/pg_ident.conf

# Copy the TLS key pair
COPY tls/*.pem /var/lib/postgresql/certs/
RUN chmod 600 /var/lib/postgresql/certs/privkey.pem \
  && chown postgres:postgres /var/lib/postgresql/certs/*

# Add the registry PostgreSQL user, create the registry database and add
# extensions.
RUN echo -n "'" > /tmp/tmp_passwords/registry_pw.tmp \
  && cat /tmp/tmp_passwords/registry_pw >> /tmp/tmp_passwords/registry_pw.tmp \
  && echo "'" >> /tmp/tmp_passwords/registry_pw.tmp \
  && sed -f /tmp/tmp_passwords/replaceRegistryUserPw.sed -i /tmp/tmp_passwords/createRegistryUser.sql \
  && /etc/init.d/postgresql start \
  && sudo -u postgres PGPASSFILE="/var/lib/postgresql/.pgpass" psql -f /tmp/tmp_passwords/createRegistryUser.sql \
  && echo -n "localhost:5432:*:registry:" >> /var/lib/postgresql/.pgpass \
  && cat /tmp/tmp_passwords/registry_pw >> /var/lib/postgresql/.pgpass \
  && echo "" >> /var/lib/postgresql/.pgpass \
  && sudo -u postgres PGPASSFILE="/var/lib/postgresql/.pgpass" createdb --owner=registry --encoding=UTF8 --lc-collate=en_US.UTF-8 --lc-ctype=en_US.UTF-8 registry \
  && sudo -u postgres PGPASSFILE="/var/lib/postgresql/.pgpass" psql -c "CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;" registry \
  && sudo -u postgres PGPASSFILE="/var/lib/postgresql/.pgpass" psql -c "CREATE EXTENSION IF NOT EXISTS fuzzystrmatch WITH SCHEMA public;" registry \
  && sudo -u postgres PGPASSFILE="/var/lib/postgresql/.pgpass" psql -c "CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;" registry \
  && /etc/init.d/postgresql stop

RUN rm -rf /tmp/tmp_passwords /core

EXPOSE 5432

COPY etc/container/ /etc/container/
ENTRYPOINT ["/etc/container/postgresql-entrypoint.sh", "interactive"]

# We've commented this out because this image is used as a base for other
# images and Docker doesn't do what we want when we go to update
# /var/lib/postgresql in child images if we specify a VOLUME in the parent.
# If you want this, uncomment here and set USE_HOST_VOLUMES=1 in config.env.
#VOLUME /var/lib/postgresql
