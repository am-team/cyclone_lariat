FROM ruby:3.3.5-alpine
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        postgresql-client
WORKDIR /gem
COPY lib/cyclone_lariat/version.rb ./lib/cyclone_lariat/version.rb
COPY cyclone_lariat.gemspec ./
COPY Gemfile* ./
RUN bundle install --jobs 20 --retry 5
CMD ["rake"]
