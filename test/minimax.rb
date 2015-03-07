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
].each do |string|
  b = Board.new(size, size, win_len, string)
  s = MinimaxStrategy.new(b, 'r')
  puts "#################################"
  puts b.board_picture

  ['r', 'b'].each do |player|
    puts "player #{player}"
    s.minimax(player)
    #move = s.best_move(player)
    #puts "best_move for #{player}: #{move}"
  end
end
