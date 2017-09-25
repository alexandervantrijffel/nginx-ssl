FROM ubuntu:16.04
MAINTAINER Alexander van Trijffel, Structura

# Environments vars
ENV TERM=xterm

RUN apt-get update
RUN apt-get -y upgrade

# Packages installation
RUN DEBIAN_FRONTEND=noninteractive apt-get -y --fix-missing install \
      software-properties-common \
      apt-transport-https \
      curl \
      supervisor \
      ca-certificates

RUN add-apt-repository ppa:certbot/certbot
RUN apt-get update && apt-get install python-certbot-nginx -y

# install nginx
RUN echo "deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/sources.list.d/nginx.list
RUN echo "deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx" >> /etc/apt/sources.list.d/nginx.list
RUN curl http://nginx.org/keys/nginx_signing.key -o /tmp/nginx_signing.key
RUN apt-key add /tmp/nginx_signing.key
RUN apt-get update
RUN DEBIAN_FRONTEND="noninteractive" apt-get install -y nginx-full

# Supervisor conf
ADD config/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Nginx conf
ADD config/nginx/nginx-site.conf /etc/nginx/sites-available/default
ADD config/nginx/nginx-site-ssl.conf /etc/nginx/sites-available/default-ssl
RUN ln -s /etc/nginx/sites-available/default-ssl /etc/nginx/sites-enabled/default-ssl
ADD config/nginx/ssl/nginx-selfsigned.key /etc/ssl/private/nginx-selfsigned.key
ADD config/nginx/nginx.conf /etc/nginx/nginx.conf
ADD config/nginx/snippets/* /etc/nginx/snippets/
RUN update-rc.d -f nginx remove

RUN mkdir -pv /etc/ssl/certs
RUN curl -k https://curl.haxx.se/ca/cacert.pem -o /etc/ssl/certs/cacert.pem
ADD config/nginx/ssl/nginx-selfsigned.crt /etc/ssl/certs/nginx-selfsigned.crt
ADD config/nginx/ssl/dhparam.pem /etc/ssl/certs/dhparam.pem
RUN update-ca-certificates

# Add index.html and 404.html to public web dir
RUN mkdir -pv /var/www/html
RUN echo "<h1>Welcome to nginx-ssl</h1>" >> /var/www/html/index.html
RUN echo "<h1>File not found (404)</h1>" >> /var/www/html/404.html
RUN chown -R www-data:www-data /var/www
RUN chmod 755 /var/www

RUN mkdir -pv /var/log/nginx
RUN touch /var/log/nginx/error.log
RUN touch /var/log/nginx/access.log

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

WORKDIR /var/www/html/

# Ports: nginx
EXPOSE 80 443

# cleanup apt and lists
RUN apt-get clean
RUN apt-get autoclean

RUN mkdir -pv /var/log/supervisor
CMD ["/usr/bin/supervisord"]
