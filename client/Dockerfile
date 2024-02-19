FROM node:21-alpine
WORKDIR /usr/src/app
COPY . .
RUN yarn install
RUN yarn run build
EXPOSE 5173
CMD [ "yarn", "start" ]