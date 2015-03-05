#! /usr/bin/env ruby
require_relative '../lib/strategy'
include PushFour

size = 6
win_len = 4
[
=begin
 '++++++
  ++++++
  +#r+++
  +#r+++
  ++++++
  ++++++',
=end
 '++++++
  ++++++
  +#rb++
  +#rb++
  ++++++
  ++++++',
=begin
 '++++++
  ++++++
  +#rb++
  ++#rb+
  +++++#
  ++++++',
=end
].each do |string|
  b = Board.new(size, size, win_len, string)
  s = Strategy.new(b, 'r')
  puts "#################################"
  puts b.board_picture

  ['r', 'b'].each do |player|
    puts "player #{player}"
    move = s.best_move(player)
    puts "best_move for #{player}: #{move}"
  end
end
