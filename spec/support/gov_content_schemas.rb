require 'govuk-content-schema-test-helpers'
require 'govuk-content-schema-test-helpers/rspec_matchers'

RSpec.configuration.include GovukContentSchemaTestHelpers::RSpecMatchers

GovukContentSchemaTestHelpers.configure do |config|
  config.schema_type = 'publisher_v2'
  config.project_root = Rails.root
end
