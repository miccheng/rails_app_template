remove_file "README.rdoc"
create_file "README.md", "TODO"

file 'config/puma.rb', <<-CODE
workers Integer(ENV['WEB_CONCURRENCY'] || 2)
threads_count = Integer(ENV['MAX_THREADS'] || 5)
threads threads_count, threads_count

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
CODE

file 'Procfile', <<-CODE
web: bundle exec puma -C ./config/puma.rb
CODE

file '.env', <<-CODE
RACK_ENV=development
PORT=3000
CODE

file 'config/database-travis.yml', <<-CODE
test:
  adapter: postgresql
  database: travis_ci_test
  username: postgres
CODE

file '.travis.yml', <<-CODE
language: ruby
rvm:
  - #{RUBY_VERSION}
addons:
  postgresql: '9.3'
bundler_args: "--without production --jobs=3"
cache: bundler
before_script:
  - psql -c 'create database travis_ci_test;' -U postgres
  - cp config/database-travis.yml config/database.yml
  - bundle exec rake db:schema:load RAILS_ENV=test
CODE

append_file ".gitignore", ".env"

gem 'slim-rails'
gem 'puma'

gem_group :development, :test do
  gem 'rspec-rails'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'better_errors'
  gem 'spring-commands-rspec'
end

gem_group :production do
  gem 'rails_12factor'
  # gem 'newrelic_rpm'
end

run 'bundle install'
generate 'rspec:install'

if yes? "Do you want to generate a root controller?"
  name = ask("What should it be called?").underscore
  generate :controller, "#{name} index --no-helper --no-assets --no-controller-specs --no-view-specs"
  route "root to: '#{name}\#index'"
end

if yes? "Do you want to create a Git repo?"
  git :init
  git add: "."
  git commit: "-a -m 'initial commit'"
end
