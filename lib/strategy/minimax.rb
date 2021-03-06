require_relative '../strategy'
require_relative '../board_light'

module PushFour

  class MinimaxStrategy < Strategy
    include BoardLight

    MAX_SCORE = 10
    MAX_DEPTH = 5

    def initialize(*args)
      super
      @minimax_call_count = 0
    end

    def best_move(b, rows, cols, player)
      if done?(b, rows, cols)
        #puts "best_move: done"
        return false
      else
        return top(b, rows, cols, player, true)
      end
    end

    def top(b, rows, cols, player, prune = true)
      debug = false
      start = Time.now

      if done?(b, rows, cols)
        return false
      end

      # Get a list of candidate moves
      if prune
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
      boards = {}

      moves.keys.each do |move|
        boards[move] = b.dup
        unless apply_move!(boards[move], rows, cols, player, *move)
          puts "invalid move #{move}"
          puts picture boards[move], rows, cols
          fail
        end

        score = score(boards[move], rows, cols, player, 0)

        # Immediately return if this is a winning move
        if score == MAX_SCORE
          puts "  top level winning move #{move} found" if debug
          return move
        elsif score == -MAX_SCORE && !(moves.count == 1)
          moves.delete(move)
          boards.delete(move)
          next
        end
      end

      return moves.keys.first if moves.count == 1

      threads = []
      lock = Mutex.new
      thread_count = 0
      moves.each do |move, pos|
        {} while thread_count > 3
        lock.synchronize { thread_count += 1 }
        threads << Thread.new do
          #puts "new thread for move #{move}"
          score = minimax(boards[move], rows, cols, opponent(player), 1, prune)
          lock.synchronize do
            scores[move] = score
            thread_count -= 1
            #puts "thread for move #{move} done"
          end
        end
      end

      threads.each { |t| t.join }

      # Return the max (or min) score
      puts "scores: #{scores.inspect}"
      puts "#{Time.now - start} sec"
      return scores.keys.max { |a,b| scores[a] <=> scores[b] }
    end

    def minimax(b, rows, cols, player, depth = 0, prune = false)
      debug = false
      @minimax_call_count += 1

      if debug #|| depth == 1
        puts "#minimax with depth #{depth}, count #{@minimax_call_count}"
        puts picture b, rows, cols
      end

      if done?(b, rows, cols)
        #puts "minimax: done"
        if depth == 0
          return false
        else
          return score(b, rows, cols, player, depth)
        end
      end

      if depth == MAX_DEPTH
        puts "max depth reached, returning 0" if debug
        return 0
      end

      min_or_max = (depth.even? ? :max : :min)

      # Get a list of candidate moves
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
        puts "depth #{depth} move #{move}" if depth == 0 #&& debug
        b_temp = b.dup

        # Apply the move; skip if invalid move
        next unless apply_move!(b_temp, rows, cols, player, *move)

        score = score(b_temp, rows, cols, player, depth)

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
        puts scores.inspect
        return scores.keys.max { |a,b| scores[a] <=> scores[b] }
      else
        return scores.values.send(min_or_max)
      end
    end

    def score(board, rows, cols, player, depth)
      winner = winner(board, rows, cols)
      return 0 unless winner

      score = MAX_SCORE
      score = -score if winner == opponent(player)
      score = -score if depth.odd?
      score
    end
  end
end
