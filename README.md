# site-ffdo-l2tp

Freifunk Dortmund (ffdo) specific Gluon configuration using l2tp and the build script.

## Using the Dockerfile

See [Docker Installation](https://docs.docker.com/install/) on how to get Docker.

```
./build.sh
```

## Cleaning up

```
docker rm ffdobuild
docker rmi ffdobuild
```

## Updating the site configuration

Change the files in the folder sites and call make-all-site-conf.sh to upgrade
the site configuration for all domains in the generated folder.

## Note 

Using build script 'build_all_lede.sh' from [Freifunk Münster](https://github.com/FreiFunkMuenster/tools). 
