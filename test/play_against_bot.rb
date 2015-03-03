#! /usr/bin/env ruby
require_relative '../lib/strategy'
include PushFour

size = 8
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

  if player == 'r'
    move = s.best_move(player)
  else
    loop do
      input = gets.split(' ')
      move = [input[0].to_sym, input[1].to_i] rescue nil

      valid = b.try_move(*move) rescue false
      if valid
        break
      else
        puts "invalid"
      end
    end
  end

  puts move.inspect
  puts "move for #{player}: #{move}"
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
