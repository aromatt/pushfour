require_relative '../strategy.rb'

module PushFour
  class SmartShallowStrategy < Strategy

    def initialize(board, player)
      super

      @prob_map = refresh_prob_map
    end

    def best_move(player = @player, generous = false)
      debug = false

      @timing[:best_move] ||= 0
      start_time = Time.now

      # if first move, consider all positions
      generous = true if @board.poses_for(player).count == 0

      @prob_map = refresh_prob_map
      candidates = generous ? @board.empty_pos : get_candidates(player)
      #candidates = @board.empty_pos
      scored = []
      candidates.each do |c|
        #puts "candidate #{c}" if debug

        move = @board.find_move(c)
        next unless move
        #puts " found move for c: #{move}" if debug

        # try the move and see how the board looks after
        b_temp = @board.apply_move(player, *move)

        #if debug
          #puts "considering this state:"
          #puts b_temp.board_picture
        #end

        my_power = player_power(player, b_temp)
        puts " my_power: #{my_power}" if debug
        opp_power = player_power(opponent(player), b_temp, true) #TODO
        puts " opp_power: #{opp_power}" if debug


        # Immediately return any move that IS a win, and
        # throw out any candidate that gives an opponent a win
        if opp_power == 1.0 / 0.0
          next
        elsif my_power == 1.0 / 0.0
          return move
        end

        score = my_power - opp_power

        puts " score: #{score}" if debug
        scored << [move, score]
      end
      sorted = scored.to_a.sort_by { |c| c[1] }

      if sorted.any?
        @timing[:best_move] += Time.now - start_time
        return sorted.last[0]
      else
        # Didn't find any good candidates; expand search to all empty positions
        # but don't get caught in endless recursion
        unless generous
          return best_move(player, true)
        else
          return @board.random_move
        end
      end
    end

    def player_power(player = @player, board = @board, lookahead = false)
      debug = false
      puts "computing power for player #{player}" if debug
      @timing[:player_power] ||= 0
      start_time = Time.now

      b = board
      cur_poses = b.poses_for(player)
      puts "power: cur poses: #{cur_poses}" if debug

      #wins_by_pos = Hash.new { |h,k| h[k] = [] }
      pathsets_by_pos = Hash.new { |h,k| h[k] = [] }

      # for de-duping
      #all_wins = {}
      all_pathsets = {}

      cur_poses.each do |cur_pos|
        pathsets = b.valid_win_pathsets(cur_pos, player)
        puts " pos #{cur_pos}: #{pathsets.count} pathsets" if debug
        pathsets.each do |ps|
          unless all_pathsets[ps]
            pathsets_by_pos[cur_pos] << ps
            all_pathsets[ps] = true
          end
        end
      end

      puts "wins: #{wins_by_pos.inspect}" if debug
      win_dists = []
      pathsets_by_pos.each do |cur_pos, pathsets|
        puts " win pathsets for #{cur_pos}" if debug
        pathsets.each do |pathset|
          puts "  win pathset #{pathset.inspect}" if debug
          win_dist = pathset.flatten.uniq.count
          puts "   win_dist #{win_dist}" if debug
          win_dist = [win_dist - 1, 0].max if lookahead
          win_dists << win_dist
        end
      end

      # no wins in sight.
      win_dists << @board.num_empty if win_dists.empty?

      @timing[:player_power] += Time.now - start_time
      score = dists_to_power(win_dists)
      puts " dists for player #{player}: #{win_dists}, score: #{score}" if debug
      score
    end

    # Take in an array of win distances and return a score
    def dists_to_power(dists)
      debug = false
      num_empty = @board.num_empty

      style = 'average'

      score = 0
      case style
      when 'additive'
        score = dists.inject(0.0) { |a,d| a + @prob_map[d] }
      when 'average'
        score = dists.inject(0.0) { |a,d| a + @prob_map[d] } / dists.count
      when 'min'
        score = @prob_map[dists.min]
      else
        fail "no style"
      end
      puts "#{score} is the score for #{dists.inspect}" if debug
      return score
    end

    def refresh_prob_map
      map = {}
      (0..@board.num_empty).each do |x|
        map[x] = 1 / (x.to_f**3)
      end
      #map[0] = 1.0 / 0.0 #200_000_000 # TODO
      map
    end
  end
end
