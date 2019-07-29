#!/usr/bin/env ruby
# typed: true
require './prism_rss'

NB_LOOPS = if ENV['NB_LOOPS'].to_i > 0
             ENV['NB_LOOPS'].to_i
           elsif ENV['NB_LOOPS'].to_i < 0
             Float::INFINITY
           else
             1
           end
# Sleep time (in minutes)
MIN_SLEEP_TIME = 1
DEF_SLEEP_TIME = 10
SLEEP_TIME = if ENV['SLEEP_TIME'].nil?
               DEF_SLEEP_TIME
             else
               [ENV['SLEEP_TIME'].to_i, MIN_SLEEP_TIME].max
             end

begin
  (1..NB_LOOPS).each do |i|
    puts "#{Time.now} run #{i}"
    PrismRSS.new.run(ARGV[0])
    if i < NB_LOOPS
      puts "#{Time.now} Sleep #{SLEEP_TIME} minutes"
      sleep(SLEEP_TIME * 60)
    end
  end
  puts "#{Time.now} done"
rescue => e
  puts(e.message)
  puts(e.backtrace.join("\n"))
end
