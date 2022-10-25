FROM ruby:latest
WORKDIR /app
ADD Image-ExifTool-12.49.tar.gz .
COPY views/ views/
COPY Gemfile Gemfile.lock app.rb config.ru .
RUN bundle install
CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0"]
EXPOSE 9292
