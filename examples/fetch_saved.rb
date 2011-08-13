#!/usr/bin/env ruby

require 'rubygems'
require 'ruby_reddit_api'
require 'yaml'

r = Reddit::Api.new 'USERNAME', 'PASSWORD'
r.login

all = Array.new
i = count = 0
max_requests = 5

begin
  puts "Request #{i += 1}"

  res = r.saved :count => count, :after => r.after, :limit => 100
  res && res.each do |s|
    all.push(s.to_hash.reject! { |key,val| ![:permalink, :title, :url].include?(key) })
    count += 1
  end
  puts "Got #{res.count} submissions" if res && res.count

  sleep Reddit::Base.throttle_duration
end until r.after.nil? || i == max_requests

puts all.to_json
