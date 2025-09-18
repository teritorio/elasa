FROM ruby:3.4-alpine

RUN apk add --no-cache --virtual \
        build-dependencies \
        build-base \
        libbz2 \
        libpq-dev \
        postgresql-dev \
        ruby-dev \
        yaml-dev

WORKDIR /srv/app

ADD Gemfile Gemfile.lock ./
RUN bundle config --global silence_root_warning 1
RUN bundle install

ADD . ./

EXPOSE 12000

HEALTHCHECK \
    --start-interval=1s \
    --start-period=30s \
    --interval=30s \
    --timeout=20s \
    --retries=5 \
    CMD wget --no-verbose --tries=1 -O /dev/null http://127.0.0.1:12000/up || exit 1
