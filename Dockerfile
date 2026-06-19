FROM nginx:1.23.3-alpine

RUN apk update && apk add --upgrade curl libcurl tiff ncurses-libs ncurses-terminfo-base libx11 libexpat

COPY default.conf /etc/nginx/conf.d

COPY ./build/web /usr/share/nginx/html
