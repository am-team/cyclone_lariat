FROM ruby:2.6.5-buster
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client
WORKDIR /gem
COPY lib/cyclone_lariat/version.rb ./lib/cyclone_lariat/version.rb
COPY cyclone_lariat.gemspec ./
COPY Gemfile* ./
RUN bundle install --jobs 20 --retry 5
CMD ["rake"]
