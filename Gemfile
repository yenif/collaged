source 'https://rubygems.org'

ruby '3.3.0'
gem 'rails', '~> 7.2'
gem 'bootsnap', require: false
gem "rails_best_practices"

gem 'mongo', '~> 2.13'
gem 'bson', '~> 4.0'
gem 'mini_racer'
gem 'mongoid', '~> 9.0'
gem 'uuidtools'
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem 'rmagick', '~> 4.0'

# Assets - Rails 4.2 moved these out of the assets group
gem 'sass-rails', '~> 5.0'
gem 'coffee-rails', '~> 4.1'
gem 'uglifier', '>= 1.3.0'

gem 'jquery-rails'

# Use unicorn as the web server
# gem 'unicorn'

group :yenif, :development, :test, :cucumber do
  gem 'listen', '~> 3.0'
  gem 'byebug'
  gem 'test-unit', '~> 3.0'
  gem 'turn', :require => false
  gem 'factory_bot_rails'
  gem 'capybara', '~> 3.0'
  gem 'cucumber-rails', :require => false
  gem "json_spec", :require => false
  gem 'spork'
  gem 'launchy'
  gem 'rspec-rails', '~> 3.9'
  gem 'mongoid-rspec'
  gem 'database_cleaner'
end
