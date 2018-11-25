#!/usr/bin/env ruby
require './prism_rss'

begin
  PrismRSS.new.run
rescue => e
  puts(e.message)
  puts(*e.backtrace)
end
