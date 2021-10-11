require 'bundler/setup'
require 'pg_fulltext'
require 'with_model'

RSpec.configure do |config|
  config.expect_with :rspec do |expects|
    expects.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end

  config.extend WithModel
end

require 'support/database'
