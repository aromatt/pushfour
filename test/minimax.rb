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
  # For minimax, the Strategy uses a plain board string, instead of a Baord
  b = Board.new(size, size, win_len, string).board_string

  s = MinimaxStrategy.new(b, 'r')

  puts "#################################"
  puts picture(b, size, size)

  ['r', 'b'].each do |player|
    puts "player #{player}"
    s.minimax(b, size, size, player)
  end
end
