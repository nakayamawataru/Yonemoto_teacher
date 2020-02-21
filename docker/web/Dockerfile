FROM ruby:2.5.1

ENV LANG C.UTF-8
ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && \
    apt-get install -y curl apt-transport-https wget && \
    curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get install -y --no-install-recommends \
    vim-tiny vim cron \
    nodejs \
    libmagic-dev \
    libpq-dev && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /app

ENV GEM_HOME /app/vendor/bundle
ENV BUNDLE_PATH /app/vendor/bundle
ENV BUNDLE_BIN /app/vendor/bundle/bin
ENV PATH $BUNDLE_BIN:$BUNDLE_PATH/gems/bin:$PATH

COPY ./docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

COPY ./wait-for-it.sh /
RUN chmod +x wait-for-it.sh

WORKDIR /app
