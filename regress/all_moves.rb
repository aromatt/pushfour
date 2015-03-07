#! /usr/bin/env ruby
require_relative '../lib/strategy/minimax'

include PushFour

size = 6
win_len = 4
[
 '++++++
  ++++++
  +#rb++
  +#rb++
  ++++++
  ++++++',
 '#++++#
  ##++++
  #+++++
  #+++#+
  #++++#
  #+#+++',
].each do |string|
  b = Board.new(size, size, win_len, string)
  puts "#################################"
  puts b.board_picture

  b.all_moves.each do |move, pos|
    puts move.inspect
    puts b.picture_for_mask b.pos_to_mask [pos]
    puts
  end
end
