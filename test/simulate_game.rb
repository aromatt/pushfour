#! /usr/bin/env ruby
require_relative '../lib/strategy'
include PushFour

start_time = Time.now

size = (ARGV[0] || 8).to_i
win_len = 4
b = Board.new(size, size, win_len)
b.add_random_rocks!
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
  puts "board timing: #{Board.timing.inspect}"
  puts "board caching: #{Board.caching.inspect}"
  puts "strategy timing: #{s.timing.inspect}"
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
puts "\n#{Time.now - start_time} sec"
