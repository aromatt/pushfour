#! /usr/bin/env ruby

require_relative '../lib/board.rb'
include PushFour

size = 7
string = '
+++++++
+++#+++
+++++#+
+++++++
+++++++
+++++++
+++++++
'

b = Board.new(size, size, 4, string)

puts b.board_picture
puts
[
  [4,3],
  [3,4],
].each do |x,y|
  puts "distance to (#{x},#{y}) is #{b.distance_to b.xy_to_pos(x,y)}"

  puts
end
