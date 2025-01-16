# Base image
FROM ruby:3.2.0

# Set environment variables
ENV RAILS_ENV production
ENV NODE_ENV production

# Install dependencies
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev default-mysql-client default-libmysqlclient-dev pv nodejs yarn redis-server

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install 

# Copy the application code
COPY . .


#RUN RAILS_ENV=production bundle exec rake assets:precompile

# Expose the application port
EXPOSE 8050

# Command to run the app
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
