require_relative '../strategy'
require_relative '../board_light'

module PushFour
  include BoardLight

  class MinimaxStrategy < Strategy

    def minimax(b, rows, cols, player)
      minmax = (player == @player ? :max : :min)

      moves = all_moves(board, rows, cols)
      puts "moves: #{moves.inspect}"
      scores = moves.map do |move, pos|
        b_temp = b.dup
        next unless apply_move!(b_temp, rows, cols, player, *move)

        score = score(b_temp, rows, cols, player)
      end
    end

    def score(board, rows, cols, player)
      return 10 if won?(board, rows, cols, player)
      return -10 if won?(board, rows, cols, opponent(player))
    end
  end
end
