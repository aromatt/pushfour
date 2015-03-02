#! /usr/bin/env ruby
require_relative '../lib/strategy'
include PushFour

size = 6
win_len = 4
string =
 '++++++
  +++#++
  ++++++
  +#b+++
  ++++++
  +++#++'

b = Board.new(size, size, win_len, string)
s = Strategy.new(b, 'r')
player = 'r'
i = 1
loop do
  puts "########################################"
  puts b.board_picture
  puts "current player: #{player}"
  puts "########################################"
  move = s.best_move(player)
  puts move.inspect
  puts "best_move for #{player}: #{move}"
  b.apply_move! player, *move
  break if b.done?
  player = s.opponent(player)
  i += 1
end

puts "\n\n\n"
puts "###########################\n\n"
puts "#{i} turns"
if b.winner
  puts "#{b.winner} wins"
else
  puts "cat's game"
end
puts
puts b.board_picture
