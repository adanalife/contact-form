ENV['RACK_ENV'] = 'test'
ENV['EMAIL_RECIPIENTS'] ||= 'test@example.com'
ENV['ALLOWLIST'] ||= 'https://www.dana.lol https://staging.dana.lol'

require 'minitest/autorun'
require 'rack/test'
require 'json'

require_relative '../mailer.rb'
