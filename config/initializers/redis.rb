# frozen_string_literal: true

require 'redis'

$redis = Redis.new(url: ENV['REDIS_URL'])
