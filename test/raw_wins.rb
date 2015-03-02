#! /usr/bin/env ruby

require_relative '../lib/board.rb'
include PushFour

size = 6
b = Board.new(size, size, 4)
puts b.board_picture
puts
[0,3,6,8,10,11,15,35].each do |pos|
  puts "\nraw wins for #{pos}"
  wins = b.raw_win_mask(pos)
  puts b.picture_for_mask(wins.inject(&:|))
end
