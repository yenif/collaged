# Capybara configuration for system tests
require 'capybara/rspec'

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium_chrome_headless
  end
end

Capybara.configure do |config|
  config.default_max_wait_time = 5
  config.default_driver = :rack_test
  config.javascript_driver = :selenium_chrome_headless
end
