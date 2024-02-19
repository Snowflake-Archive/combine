FROM node:21-alpine
WORKDIR /usr/src/app
COPY . .
RUN yarn install
RUN yarn run build
EXPOSE 4173
CMD [ "yarn", "start" ]