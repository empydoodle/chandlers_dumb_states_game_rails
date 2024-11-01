FROM ruby:3.2.2
RUN apt-get update -qq && apt-get install npm -qq
ADD . /chandlers_dumb_states_game
WORKDIR /chandlers_dumb_states_game
RUN npm install --global yarn n
RUN n 16.4.0
RUN bundle install
RUN yarn add materialize-css material-icons
RUN rails webpacker:install
RUN npm install
EXPOSE 3000
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]