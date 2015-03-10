#! /usr/bin/env ruby
require_relative '../lib/strategy/minimax'

include PushFour
include BoardLight

size = 5
win_len = 4
[
=begin
 '++++++
  ++++++
  ##b+++
  +#b+++
  ++++++
  ++++++',
=end
 '+++++
  +#b++
  +#b++
  +++++
  +++++',
].each do |string|
  # For minimax, the Strategy uses a plain board string, instead of a Baord
  b = Board.new(size, size, win_len, string).board_string

  s = MinimaxStrategy.new(b, 'r')

  player = 'r'
  #1.times do
  loop do
    puts "#################################"
    puts picture(b, size, size)
    puts "player #{player}"
    move = s.best_move(b, size, size, player)
    if !move
      break
    end
    puts "best move for player #{player}: #{move}"
    apply_move!(b, size, size, player, *move)
    puts picture(b, size, size)
    player = s.opponent(player)
  end

  puts "\nWinner: #{winner(b, size, size)}"
end

