FROM elixir:1.12-alpine

RUN mkdir /build
WORKDIR /build
ENV MIX_ENV=prod

RUN apk add git

RUN mix local.hex --force
RUN mix local.rebar --force
COPY mix.exs .
COPY mix.lock .
RUN mix deps.get
RUN mix compile

COPY . .
RUN mix sentry_recompile
RUN mix release

# ---------

FROM alpine:latest
RUN apk add --no-cache libstdc++ openssl ncurses-libs dumb-init

RUN mkdir /app
WORKDIR /app

COPY --from=0 /build/_build/prod/rel ./

ENTRYPOINT ["dumb-init", "--"]
CMD ["./salad/bin/salad", "start"]
