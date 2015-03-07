#! /usr/bin/env ruby
require_relative '../lib/strategy/smart_shallow'
include PushFour

size = 6
win_len = 4
[
 '++++++
  ++++++
  +#r+++
  +#r+++
  ++++++
  ++++++',

 '++++++
  ++++++
  +#rb++
  +#rb++
  ++++++
  ++++++',

 '++++++
  ++b+++
  +#r+++
  +#r+++
  ++++++
  ++++++',

 '++++++
  ++b+++
  +#r+++
  +#r+++
  ++b+++
  ++++++',

 '++++++
  +#+#++
  +bb+++
  +rbr++
  +rr#r+
  +++r+b',

 '######
  #++++#
  #rrr++
  #++++#
  #++++#
  ####+#'
].each do |string|
  b = Board.new(size, size, win_len, string)
  s = SmartShallowStrategy.new(b, 'r')
  puts s.board.board_picture
  puts "Power: #{s.player_power}"
end
