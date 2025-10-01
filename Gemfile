source 'https://rubygems.org'

ruby '3.3.0'
gem 'rails', '~> 7.2'
gem 'bootsnap', require: false
gem "rails_best_practices"

gem 'mongo', '~> 2.13'
gem 'bson', '~> 4.0'
gem 'mini_racer'
gem 'mongoid', '~> 9.0'
gem 'sqlite3', '~> 2.0'  # For ActiveStorage only
gem 'carrierwave-mongoid', :require => 'carrierwave/mongoid'
gem 'rmagick', '~> 6.0'
gem 'image_processing', '~> 1.12'

# Assets - Rails 4.2 moved these out of the assets group
gem 'sass-rails', '~> 5.0'
gem 'coffee-rails', '~> 4.1'
gem 'uglifier', '>= 1.3.0'

gem 'jquery-rails'  # Legacy - kept for backward compatibility (not used by Stimulus controllers)

# Hotwire (Turbo + Stimulus)
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'

# Use unicorn as the web server
# gem 'unicorn'

group :yenif, :development, :test, :cucumber do
  gem 'listen', '~> 3.0'
  gem 'byebug'
  gem 'test-unit', '~> 3.0'
  gem 'factory_bot_rails'
  gem 'capybara', '~> 3.0'
  gem 'selenium-webdriver'
  gem 'cucumber-rails', :require => false
  gem "json_spec", :require => false
  gem 'launchy'
  gem 'rspec-rails', '~> 6.1'
  gem 'mongoid-rspec'
  gem 'database_cleaner'
  gem 'simplecov', require: false
  gem 'committee-rails'
end
