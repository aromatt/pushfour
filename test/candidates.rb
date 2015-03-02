#! /usr/bin/env ruby
require_relative '../lib/strategy'
include PushFour

size = 6
win_len = 4
[
 '++++++
  ++++++
  +#r+++
  +#r+++
  ++++++
  ++++++',
].each do |string|
  b = Board.new(size, size, win_len, string)
  s = Strategy.new(b, 'r')
  puts b.board_picture
  move = s.best_move
  puts "best_move: #{s.best_move}"
end
