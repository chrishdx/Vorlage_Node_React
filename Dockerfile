FROM node:18.13.0 
# 18.13.0 enstpricht 108
ENV TZ="Europe/Berlin"
RUN date
RUN apt update
RUN apt install curl gnupg2 ca-certificates lsb-release sudo -y
RUN apt install -y nginx
COPY ./backend /app
COPY ./NginxProxy/default.conf /etc/nginx/sites-available/default
COPY start.sh /start.sh
COPY ./frontend/build /var/www/html
WORKDIR /app
RUN npm install
RUN echo "Port=507" >> .env
RUN echo "JWT_SECRET=secret" >> .env
RUN echo "Cookie_Secret=produktionn" >> .env
RUN echo "NODE_ENV=production" >> .env


ENTRYPOINT [ "/start.sh" ]
