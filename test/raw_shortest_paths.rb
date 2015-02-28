#! /usr/bin/env ruby

require_relative '../lib/board.rb'
include PushFour

size = 3
b = Board.new(size, size, 3)
b.add_rock! 2

puts b.board_picture
puts
[
  [0, 4],
  [0, 5],
  [5, 0],
  [5, 5],
].each do |test|
  puts test.join ','
  paths = b.raw_shortest_paths(*test)
  puts "shortest paths from #{test[0]} to #{test[1]} (#{paths.count})"
  paths.each do |path|
    puts path.inspect
    puts b.picture_for_mask(b.pos_to_mask(*path))
    puts
  end
  puts
end
