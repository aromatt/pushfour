#! /usr/bin/env ruby
require_relative '../lib/web_interface.rb'
require_relative '../lib/strategy.rb'

include PushFour

player = 1004


loop do
  games = WebInterface.game_list(player)
  games.each do |game_id|
    info = WebInterface.game_info(game_id, player)
    b = Board.new(
      info[:y],
      info[:x],
      4,
      info[:board]
    )
    puts "game #{game_id}, player #{info[:player_color]}"
    puts b.board_picture

    s = Strategy.new(b, info[:player_color])
    move = s.best_move
    puts "move: #{move}"

    WebInterface.send_move(game_id, player, *move)
    b.apply_move! info[:player_color], *move

    puts b.board_picture
    puts
  end
  sleep 1
end
