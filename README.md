# nginx-ssl

Ubuntu 16.04 based Docker image for NGINX 

Features: 
- nginx version 1.10
- runs with supervisord
- support for SSL: 
     - default-ssl site with self signed certificate for localhost
     - balanced SSL security with A grade SSL security and optimal support for (older) browsers

Run the following command inside the docker container to register a Letsencrypt certificate:

```
certbot --nginx certonly
```

And auto renew the certificates with the following command.


```
certbot renew
```