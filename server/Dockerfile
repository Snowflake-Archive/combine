FROM oven/bun:latest
WORKDIR /usr/src/app
COPY . .
RUN bun install
RUN bun run build

EXPOSE 5678
CMD [ "bun", "run", "start" ]