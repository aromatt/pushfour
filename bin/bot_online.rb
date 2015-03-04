#! /usr/bin/env ruby
require_relative '../lib/web_interface.rb'
require_relative '../lib/strategy.rb'

include PushFour

player = 1004

finished_games = {}
loop do
  begin
  games = WebInterface.game_list(player)
  games.each do |game_id|
    info = WebInterface.game_info(game_id, player)
    start = Time.now
    b = Board.new(
      info[:y],
      info[:x],
      4,
      info[:board]
    )

    unless b.random_move
      finished_games[game_id] = true
    end
    next if finished_games[game_id]

    puts "game #{game_id}, player #{info[:player_color]}"
    puts b.board_picture

    s = Strategy.new(b, info[:player_color])
    move = s.best_move
    puts "move: #{move}"

    b.apply_move! info[:player_color], *move
    puts "#{Time.now - start} sec"

    WebInterface.send_move(game_id, player, *move)

    puts b.board_picture
    puts
    $stdout.flush
  end
  rescue => e
    puts e.message
  end
  sleep 1
end
