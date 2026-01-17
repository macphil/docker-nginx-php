FROM alpine:latest AS gitrepo
COPY .git/ /tmp/.git
WORKDIR /tmp/git
RUN apk add --no-cache git && \
    git log -1 --pretty='%h - %ci' > /git-commit.txt

  
FROM alpine:latest
LABEL Maintainer="Philip Schröder <post@macphil.de>"
LABEL Description="A minimal base image using Alpine, NGiNX & PHP"

RUN apk add --no-cache \
curl \
nginx \
php \
php-fpm && \
rm -rf /var/cache/apk/*

COPY config/nginx.non-root.conf /etc/nginx/nginx.conf
COPY app /app

# activate monitoring page
RUN sed -i "s|;ping.path = /ping|ping.path = /fpm-ping|g" /etc/php84/php-fpm.d/www.conf 


COPY --from=gitrepo /git-commit.txt /git-commit.txt
RUN GIT_COMMIT=$(cat /git-commit.txt) && \
  sed -i "s/#GIT_COMMIT#/${GIT_COMMIT}/g" /etc/nginx/nginx.conf && \
  sed -i "s/#GIT_COMMIT#/${GIT_COMMIT}/g" /app/public/index.html && \
  rm -f /git-commit.txt

EXPOSE 8080

CMD ["sh", "-c", "nginx && php-fpm84 -F"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1