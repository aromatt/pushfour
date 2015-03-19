#! /usr/bin/env ruby
require_relative '../lib/strategy/smart_shallow'
include PushFour

start_time = Time.now

size = 6
win_len = 4
string = '
++++++
++++++
++rr#+
brbr#+
++++++
++++++
'
b = Board.new(size, size, win_len, string)
s = SmartShallowStrategy.new(b, 'r')
player = 'b'
i = 1
NUM_MOVES = 1

NUM_MOVES.times do
  puts "########################################"
  puts b.board_picture
  puts "current player: #{player}"
  puts "########################################"
  move = s.best_move(player)
  puts move.inspect
  puts "best_move for #{player}: #{move}"
  b.apply_move! player, *move
  #puts "board timing: #{Board.timing.inspect}"
  #puts "board calls: #{Board.calls.inspect}"
  #puts "board caching: #{Board.caching.inspect}"
  #puts "strategy timing: #{s.timing.inspect}"
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

=begin
puts "Timing:"
Board.timing.each do |k,v|
  c = Board.calls[k]
  puts "#{k}: #{v.to_f.round(0)}s, #{c} calls, #{(v.to_f / c * 1000000).round(3)} us per call"
end
=end

puts
puts b.board_picture
puts "\n#{Time.now - start_time} sec"
