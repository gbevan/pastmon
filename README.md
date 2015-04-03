PasTmon Web App with Sensor Docker Image for CoreOS
===================================================

Part of the [PasTmon](http://pastmon.sourceforge.net) Project.

### Passive Application Monitoring for all containers running on a CoreOS host.

Provides a image for the PasTmon Web Front-end (including it's own Sensor) and a
Sensor only image.

On your frontend node:

    $ git clone https://github.com/gbevan/pastmon.git
    $ cd pastmon

Edit (or create new) pastmon-web@.service, substituting appropriate X-Fleet conditionals:

    [X-Fleet]
    MachineMetadata=frontend
    #MachineID=...  # from /etc/machine-id

Use MachineID to bind the web service to a specific frontend or use MachineMetadata to prefer a tagged node.

    $ fleetctl submit pastmon-*.service

    $ fleetctl start pastmon-web@1.service pastmon-web-discovery@1.service

You can also start PasTmon sensor containers on your other CoreOS hosts:

    $ fleetctl start pastmon-sensor@{1..5}.service

(the 1..5 tells fleet to deploy 5 containers numbered 1 through 5 - so subsitute the number of
remaining nodes in your CoreOS cluster to deploy to.)

These should auto discover your instance of pastmon-web@1 running in the cluster, via etcd.

Point your browser at http://your-front-end-host:8080, default user/password is admin/admin.

Other start options are (default values shown):

    dbport=5432
    webport=8080

These can be added to the `docker run ...` command in the pastmon-web@.service unit file (see that file for examples).
Also, if you change the dbport default, then you must update the respective value in pastmon-web-discovery@.service unit file,
so it can inform other pastmon sensors in the cluster.

The pastmon-web@service unit will create a docker container called pastmon-db, this is to
provide a persistent database volume (allowing future upgardes of the PasTmon web container
without loosing your data).

Should you need to delete the pastmon-db container and it's persistent database volume,
use `docker rm -v ...` - otherwise you end up with orphaned volumes.

### Can I Use this on an OS other than CoreOS?

Yes.  You just need a recent version of docker installed, and run the container directly:

Create the persistent db data volume container:

    $ docker create -v /var/lib/postgresql -v /var/run/postgresql --name pastmon-db busybox

Run PasTmon Web Service:

    $ docker run --name pastmon-web%i --volumes-from pastmon-db --net=host --cap-add=NET_ADMIN gbevan/pastmonweb

Run any needed PasTmon Sensors (on nodes other than PasTmon Web Services):

    $ docker run --name pastmon-sensor%i --net=host --cap-add=NET_ADMIN gbevan/pastmonsensor "dbhost=....; dbport=5432"

### Latest vs Version

Currently there is only the latest available image, tracking the PasTmon Git Master head.
Later, as new releases emerge from the PasTmon project, fixed version images will be made available.
So for now this is an experimental release.
