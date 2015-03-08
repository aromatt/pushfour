require_relative '../strategy'
require_relative '../board_light'

module PushFour

  class MinimaxStrategy < Strategy
    include BoardLight

    MAX_SCORE = 10
    MAX_DEPTH = 3

    def initialize(*args)
      super
      @minimax_call_count = 0
    end

    def best_move(b, rows, cols, player)
      if done?(b, rows, cols)
        #puts "best_move: done"
        return false
      else
        return minimax(b, rows, cols, player, 0, true)
      end
    end

    def minimax(b, rows, cols, player, depth = 0, prune = false)
      debug = false
      @minimax_call_count += 1

      if depth == 2 && debug
        puts "#minimax with depth #{depth}, count #{@minimax_call_count}"

        puts picture b, rows, cols
      end

      if done?(b, rows, cols)
        #puts "minimax: done"
        if depth == 0
          return false
        else
          return score(board, rows, cols, player)
        end
      end

      if depth == MAX_DEPTH
        puts "max depth reached, returning 0" if debug
        return 0
      end

      min_or_max = (player == @player ? :max : :min)

      if depth < MAX_DEPTH + 1 || prune
        moves = {}
        b_obj = Board.new(rows, cols, WIN_LEN, b.dup)
        get_candidates(player, b_obj).each do |pos|
          move = b_obj.find_move(pos)
          next unless move
          moves[move] = pos
        end

        # Get all moves if there were no good candidates
        if moves.empty?
          moves = all_moves(board, rows, cols)
        end
      else
        # all_moves returns a map of {[side,chan] => pos, ... }
        moves = all_moves(board, rows, cols)
      end

      scores = {}

      puts "depth #{depth} moves: #{moves.inspect}" if debug
      puts "depth #{depth} #{moves.count} moves" if depth == 0 && debug
      moves.each do |move, pos|
        puts "depth #{depth} move #{move}" if depth == 0 && debug
        b_temp = b.dup

        # Apply the move; skip if invalid move
        next unless apply_move!(b_temp, rows, cols, player, *move)

        score = score(b_temp, rows, cols, player)

        # Immediately return if this is a winning move
        if score == MAX_SCORE
          puts "  depth #{depth} winning move #{move} found" if debug
          if depth == 0
            return move
          else
            return score
          end
        end

        # Not a winning move; explore further
        score = minimax(b_temp, rows, cols, opponent(player), depth + 1, prune)

        scores[move] = score
      end

      puts "depth #{depth} scores: #{scores.inspect}" if depth == 0 && debug

      # Return the max (or min) score
      if depth == 0
        return scores.keys.max { |m| scores[m] }
      else
        return scores.values.send(min_or_max)
      end
    end

    def score(board, rows, cols, player)
      return MAX_SCORE if won?(board, rows, cols, player)
      return -MAX_SCORE if won?(board, rows, cols, opponent(player))
      0
    end
  end
end
