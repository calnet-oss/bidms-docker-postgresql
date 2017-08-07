## Purpose

This [Docker](http://www.docker.com/) image runs a
[PostgreSQL](http://www.postgresql.org/) database server and exposes the
database port on 5432.

The author does not currently publish the image in any public Docker
repository but a script, described below, is provided to easily create your
own image.

## License

The source code, which in this project is primarily shell scripts and the
Dockerfile, is licensed under the [BSD two-clause license](LICENSE.txt).

## Building the Docker image

Copy `config.env.template` to `config.env` and edit to set config values.

Create `imageFiles/tmp_passwords/postgres_pw` file and set a PostgreSQL
Administrator password, which is the 'postgres' user in the database.

Make sure it's only readable by the owner:
```
chmod 600 imageFiles/tmp_passwords/postgres_pw
```

This image depends on the the base BIDMS Debian Docker image from the
[bidms-docker-debian-base](http://www.github.com/calnet-oss/bidms-docker-debian-base)
project.  If you don't have that image built yet, you'll need that first.

Make sure the `HOST_POSTGRESQL_DIRECTORY` directory specified in
`config.env` does not exist yet on your host machine (unless you're running
`buildImage.sh` subsequent times and want to keep your existing database) so
that the build script will initialize your database.

Build the container image:
```
./buildImage.sh
```

## Running

To run the container interactively (which means you get a shell prompt):
```
./runContainer.sh
```

Or to run the container detached, in the background:
```
./detachedRunContainer.sh
```

If everything goes smoothly, the container should expose port 5432, the
PostgreSQL port.  This port is redirected to a port on the host, where the
host port number is specified in `config.env` as `LOCAL_DIR_POSTGRES_PORT`.

You can then use your favorite PostgreSQL client to connect to it.

If running interactively, you can exit the container by exiting the bash
shell.  If running in detached mode, you can stop the container with: 
`docker stop bidms-postgresql` or there is a `stopContainer.sh` script included
to do this.

To inspect the running container from the host:
```
docker inspect bidms-postgresql
```

To list the running containers on the host:
```
docker ps
```

## Database Persistence

Docker will mount the host directory specified in
`HOST_POSTGRESQL_DIRECTORY` from `config.env` within the container as
`/var/lib/postgresql` and this is how the database is persisted across
container runs.

As mentioned in the build image step, the `buildImage.sh` script will
initialize an empty database as long as the `HOST_POSTGRESQL_DIRECTORY`
directory doesn't exist yet on the host at the time `buildImage.sh` is run. 
Subsequent runs of `buildImage.sh` will not re-initialize the database if
the database exists.

If you plan on running the image on hosts separate from the machine you're
running the `buildImage.sh` script on then you'll probably want to let
`buildImage.sh` initialize a database and then copy the
`HOST_POSTGRESQL_DIRECTORY` to all the machines that you will be running the
image on.  When copying, be careful about preserving file permissions.

## Disabling Linux Transparent Hugepages

If you're running Linux, it's 
[a good idea to disable kernel transparent hugepages](https://askubuntu.com/questions/597372/how-do-i-modify-sys-kernel-mm-transparent-hugepage-enabled)
because it is not recommended for database machines and can hurt performance. 
This should be done on the host running the PostgreSQL docker container.

There are multiple ways to do this, but if you're running a flavor of Linux
with `/etc/default/grub` (such as Debian or Ubuntu), then the easiest way is
to have a `GRUB_CMDLINE_LINUX_DEFAULT` line that looks something like this:
```
GRUB_CMDLINE_LINUX_DEFAULT="transparent_hugepage=never"
```
and then execute:
```
sudo update-grub
```

Reboot and confirm with:
```
cat /sys/kernel/mm/transparent_hugepage/enabled
```

It should show:
```
always madvise [never]
```
