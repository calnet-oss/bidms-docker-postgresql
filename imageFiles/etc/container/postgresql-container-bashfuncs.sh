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

function container_startup {
  if [ -e /var/lib/postgresql/shuttingdown ]; then
    rm /var/lib/postgresql/shuttingdown
  fi
  if [ -e /var/lib/postgresql/cleanshutdown ]; then
    rm /var/lib/postgresql/cleanshutdown
  fi
  /usr/sbin/syslogd
  /etc/init.d/postgresql start
  /etc/init.d/cron start
}

function container_shutdown {
  touch /var/lib/postgresql/shuttingdown
  /etc/init.d/postgresql stop
  /etc/init.d/cron stop
  kill -TERM $(cat /var/run/syslog.pid)
  echo "Processes still running after shutdown:" > /var/lib/postgresql/cleanshutdown
  ps -uxaw >> /var/lib/postgresql/cleanshutdown
  rm /var/lib/postgresql/shuttingdown
  exit
}
