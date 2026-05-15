# Tips para construir 


## Asumiendo que estas usando tu registry en tu local y que vas a probar manualmente.

### Para imagen base de desarrolladores: Parate en dev 
#### Construye
```
docker build -t localhost:5000/base/node24-dev-debian:1.0.0 .
```

#### Pushea al registry

#### En la empresa cambia "localhost:5000" por tu registry empresa gil.

```
docker push localhost:5000/base/node24-dev-debian:1.0.0
```

#### Puedes consultar el catálogo para ver si se subió correctamente:

```
curl http://localhost:5000/v2/_catalog
```

### Para imagen base de runtime: Parate en runtime
#### Construye runtime
```
docker build -t localhost:5000/base/node24-runtime-debian:1.0.0 .
```

#### Pushea al registry

```
docker push localhost:5000/base/node24-runtime-debian:1.0.0
```

#### Consultar el catálogo para ver si se subió correctamente:

```
curl http://localhost:5000/v2/_catalog
```