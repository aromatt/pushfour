require_relative '../strategy'

module PushFour
  class MinimaxStrategy < Strategy
    def minimax(player, b = @board)
      minmax = (player == @player ? :max : :min)

      moves = b.all_moves
      moves.each do |move, pos|
        puts move.inspect
        puts b.picture_for_mask b.pos_to_mask [pos]
        puts
      end
    end

    def score(board)
    end
  end
end
