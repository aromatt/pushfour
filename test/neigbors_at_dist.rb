#! /usr/bin/env ruby

require_relative '../lib/board.rb'
include PushFour

size = 6
b = Board.new(size, size, 4)
puts b.board_picture
puts
[
  [15,1],
  [15,2],
  [15,3],
  [0,3],
  [0,0],
].each do |test|
  puts test.join ','
  n = b.neighbors_at_dist(*test)
  puts b.picture_for_mask(b.pos_to_mask(test[0], *n))
  puts
end
