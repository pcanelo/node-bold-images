# Tips para construir 


## Asumiendo que estas usando tu registry en tu local y que vas a probar manualmente.

## Para imagen base de desarrolladores: Parate en dev 
#### Construye
```
podman build -t localhost:5000/base/node14-dev-debian:1.0.0 .
o
docker build -t localhost:5000/base/node14-dev-debian:1.0.0 .
```

#### Pushea al registry

#### En la empresa cambia "localhost:5000" por tu registry empresa gil.

```
podman push localhost:5000/base/node14-dev-debian:1.0.0
o
docker push localhost:5000/base/node14-dev-debian:1.0.0
```

#### Puedes consultar el catálogo para ver si se subió correctamente:

```
curl http://localhost:5000/v2/_catalog
```

## Para imagen base de runtime: Parate en runtime
#### Construye runtime
```
podman build -t localhost:5000/base/node14-runtime-debian:1.0.0 .
o
docker build -t localhost:5000/base/node14-runtime-debian:1.0.0 .
```

#### Pushea al registry

```
podman push localhost:5000/base/node14-runtime-debian:1.0.0
o
docker push localhost:5000/base/node14-runtime-debian:1.0.0
```

#### Consultar el catálogo para ver si se subió correctamente:

```
curl http://localhost:5000/v2/_catalog
```