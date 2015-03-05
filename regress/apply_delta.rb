#! /usr/bin/env ruby

require_relative '../lib/board.rb'
include PushFour

size = 6
b = Board.new(size, size, 4)
puts b.board_picture
puts

[
  [15, 1, 2],
  [0, 1, 2],
  [0, -1, 2],
  [35, 0, 0],
  [35, -1, 0],
  [35, -1, 1],
  [29, 1, 0],
].each do |test|
  puts test.join ','
  dest = b.apply_delta(*test)
  if dest
    puts b.picture_for_mask(b.pos_to_mask([test[0], dest]))
  else
    puts "off board"
  end
  puts
end
