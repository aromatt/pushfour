#! /usr/bin/env ruby

require_relative '../lib/board.rb'
include PushFour

size = 3
b = Board.new(size, size, 2, '+r#+#b+r+')

puts b.board_string
puts b.rock_mask.to_s(2)
puts b.blue_mask.to_s(2)
puts b.red_mask.to_s(2)
b.apply_move('b', :right, 0)
b.apply_move('r', :bottom, 1)
b.apply_move('r', :bottom, 1)
b.apply_move('b', :right, 2)
b.apply_move('r', :left, 2) # blocked
b.apply_move('r', :right, 2)
puts b.board_picture
