# This file is copied to spec/ when you run 'rails generate rspec:install'

# SimpleCov coverage reporting
if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start 'rails' do
    add_filter '/spec/'
    add_filter '/config/'
    add_filter '/vendor/'

    minimum_coverage 90
    minimum_coverage_by_file 80
  end
end

ENV["RAILS_ENV"] = 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  # Mongoid test database cleanup
  config.before(:each) do
    Mongoid.purge!
  end
end
