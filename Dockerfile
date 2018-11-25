FROM ruby:2

# Speeds up bundle install if source changed
RUN gem install nokogiri -v 1.8.5

COPY . /app

WORKDIR /app

RUN bundle install

CMD [ "bundle", "exec", "run.rb" ]