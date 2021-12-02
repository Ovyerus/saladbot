FROM elixir:1.12-alpine

RUN mkdir /app
WORKDIR /app
ENV MIX_ENV=prod

RUN apk add dumb-init git

RUN mix local.hex --force
RUN mix local.rebar --force
COPY mix.exs .
COPY mix.lock .
RUN mix deps.get
RUN mix compile

COPY . .
# RUN mix sentry_recompile
RUN mix release

ENTRYPOINT ["dumb-init", "--"]
CMD ["sh", "entrypoint.sh"]