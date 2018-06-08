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


## Note 

Using build script 'build_all_lede.sh' from [Freifunk Münster](https://github.com/FreiFunkMuenster/tools). 
