require 'net/http'

# UI for a game:
# http://pushfour.net/index.php?game=2743

def get(url)
  uri = URI(url)
  Net::HTTP.get(uri)
end

module PushFour
  module WebInterface
    SERVER_URL = 'http://pushfour.net'

    def self.game_list(player)
      res = get "#{SERVER_URL}/getgames.php?playerid=#{player.to_i}"
      res.split(',').reject{|id| id == '0'}.map{|id| id.to_i}
    end

    def self.game_info(game_id, player)
      res = get "#{SERVER_URL}/gameinfo.php?gameid=#{game_id.to_i}&playerid=#{player.to_i}"
      parse_game_string(res, game_id)
    end

    def self.parse_game_string(str, id = nil)
      info = str.split(',')
      {
        open_char: info[0],
        board: info[1],
        y: info[2].to_i,
        x: info[3].to_i,
        player_count: info[4].to_i,
        chars: info[5].chars.map {|c| c},
        player_color: info[6]
      }

    end

    # NOTE: channel is a symbol, not a string; it is mapped to 't', 'b', 'l', 'r' below
    def self.send_move(game_id, player, side, channel)
      side = {left: 'l', right: 'r', top: 't', bottom: 'b'}[side]
      params = {
        'game' => game_id,
        'player' => player,
        'side' => side,
        'channel' => channel
      }
      param_str = params.to_a.map {|kv| kv.join('=')}.join('&')

      get "#{SERVER_URL}/manager.php?#{param_str}"
    end
  end
end
