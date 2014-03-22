# encoding: UTF-8

require 'rspec'
require 'scuttle'
require 'pry-nav'

RSpec.configure do |config|
  config.mock_with :rr
end

def convert(sql_string)
  Scuttle.convert(sql_string)
end