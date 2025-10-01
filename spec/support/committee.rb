# Committee OpenAPI contract validation
require 'committee/rails'

RSpec.configure do |config|
  config.include Committee::Rails::Test::Methods, type: :request

  # Configure committee if OpenAPI schema exists
  openapi_path = Rails.root.join('docs/openapi.yaml')
  if File.exist?(openapi_path)
    config.add_setting :committee_options
    config.committee_options = {
      schema_path: openapi_path.to_s,
      validate_success_only: false,
      parse_response_by_content_type: true
    }
  end
end
