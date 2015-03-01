#! /usr/bin/env ruby

require_relative '../lib/board.rb'
include PushFour

size = 4
string = '
++++
+#+#
++#+
+++#
'

b = Board.new(size, size, 4, string)

puts b.board_picture
puts
[
  0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
].each do |pos|
  puts "Finding path to #{pos}"
  puts "path to #{pos} is #{b.find_path pos}"
  puts
end
