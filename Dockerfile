FROM node:latest

MAINTAINER Arseniy Ivanov

WORKDIR /src
COPY package.json ./

RUN npm install -g coffee-script
RUN npm install

COPY . ./

USER nobody
RUN env
ENTRYPOINT ["coffee", "index.coffee"]
