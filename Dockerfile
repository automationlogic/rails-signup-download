FROM rails-base

RUN rake db:migrate RAILS_ENV=development
