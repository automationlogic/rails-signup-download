FROM ruby:2.2.0
MAINTAINER sam@automationlogic.com

# This file is a mix of the rails:onbuild and rails:4.2.3 dockerfiles, but using ruby:2.2.0 as the base

RUN apt-get update && apt-get install -y nodejs --no-install-recommends && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y mysql-client postgresql-client sqlite3 --no-install-recommends && rm -rf /var/lib/apt/lists/*

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app

ADD Gemfile /usr/src/app/
ADD Gemfile.lock /usr/src/app/
RUN bundle install

ADD . /usr/src/app

RUN rake db:migrate RAILS_ENV=development

EXPOSE 3000
CMD ["rails", "server", "-b", "0.0.0.0"]
