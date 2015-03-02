require_relative 'board'


# TODO
#      - log every game it plays
#      - sometimes you can block by moving to get in someone's way, but not
#        necessarily in one of their win paths
#        - actually, it sort of half does this
#      - search deeper on less certain branches of tree
#      - include diversity in power score (number of unique positions in
#        wins. ==> lots of ways to win? or bottleneck?
#      - consider how in control you are
#        - how many options does the opponent have


module PushFour
  class Strategy

    attr_accessor :board, :player
    def initialize(board, player)
      fail unless board && player
      @board = board
      @player = player

      @prob_map = refresh_prob_map
    end

    # TODO
    def opponent(player = @player)
      {'r' => 'b', 'b' => 'r'}[player]
    end

    def best_move(player = @player)
      debug = false
      @prob_map = refresh_prob_map
      candidates = @board.empty_pos #get_candidates(player) #TODO
      b_temp = Board.new(
        @board.rows,
        @board.columns,
        @board.win_len,
        @board.board_string
      )
      scored = []
      candidates.each do |c|
        b_temp.board_string = @board.board_string.dup
        puts "candidate #{c}" if debug
        move = b_temp.find_move(c)
        next unless move
        puts " found move for c: #{move}" if debug

        # try the move and see how the board looks after
        b_temp.apply_move!(player, *move)

        if debug
          puts "considering this state:"
          puts b_temp.board_picture
        end

        score = player_power(player, b_temp) -
                player_power(opponent(player), b_temp, true) # lookahead is a hack, right?

        puts " score: #{score}" if debug
        scored << [move, score]
      end
      sorted = scored.to_a.sort_by { |c| c[1] }
      return sorted.last[0] if sorted.any?

      # TODO instead of random, should open up candidate space
      rando = @board.random_move
      puts "rando! #{rando}"
      return rando
    end

    def get_candidates(player = @player)
      debug = false
      b = @board
      candidates = []

      [player, opponent(player)].each do |role|
        candidates += b.poses_for(role).map do |pos|
          b.valid_win_pathsets(pos, role)
        end.flatten
      end

      if debug
        puts "candidates:"
        puts b.picture_for_mask b.pos_to_mask candidates
      end
      # what TODO if there are no pieces on the board, include rocks?
      candidates.uniq
    end

    def refresh_prob_map
      map = {}
      (1..@board.num_empty).each do |x|
        map[x] = 1 / (x.to_f**3)
      end
      map[0] = 200_000_000 # TODO
      map
    end

    def player_power(player = @player, board = @board, lookahead = false)
      debug = false
      b = board
      cur_poses = b.poses_for(player)
      puts "power: cur poses: #{cur_poses}" if debug

      #wins_by_pos = Hash.new { |h,k| h[k] = [] }
      pathsets_by_pos = Hash.new { |h,k| h[k] = [] }

      # for de-duping
      #all_wins = {}
      all_pathsets = {}

      cur_poses.each do |cur_pos|
=begin
        wins = b.valid_wins(cur_pos, player)
        wins.each do |win|
          unless all_wins[win]
            wins_by_pos[cur_pos] << win
            all_wins[win] = true
          end
        end
=end
        pathsets = b.valid_win_pathsets(cur_pos, player)
        pathsets.each do |ps|
          unless all_pathsets[ps]
            pathsets_by_pos[cur_pos] << ps
            all_pathsets[ps] = true
          end
        end
      end

      #puts "wins: #{wins_by_pos.inspect}" if debug
      win_dists = []
      pathsets_by_pos.each do |cur_pos, pathsets|
        puts "pathsets for #{cur_pos}" if debug
        pathsets.each do |pathset|
          puts " pathset #{pathset.inspect}" if debug
          win_dist = pathset.flatten.uniq.count
          puts "  win_dist #{win_dist}" if debug
          win_dist = [win_dist - 1, 0].max if lookahead
          win_dists << win_dist
        end
      end

=begin
      win_dists = []
      wins_by_pos.each do |cur_pos, win_set|
        puts "wins for pos #{cur_pos}" if debug
        win_set.each do |win|
          puts "win #{win}" if debug
          paths = win.
            reject { |pos| b.board_string[pos] == player }.
            map { |pos| b.find_path(pos) }
          puts "  paths: #{paths.inspect}" if debug
          win_dist = paths.flatten.uniq.count
          win_dists << win_dist
          puts "    win_dist: #{win_dists.last}" if debug
        end
      end
=end


      # pitiful. no wins in sight.
      win_dists << @board.num_empty if win_dists.empty?

      puts "dists for player #{player}: #{win_dists}" if debug
      dists_to_power(win_dists)
    end

    def dists_to_power(dists)
      num_empty = @board.num_empty

      style = 'average'

      case style
      when 'additive'
        return dists.inject(0.0) { |a,d| a + @prob_map[d] }
      when 'average'
        return dists.inject(0.0) { |a,d| a + @prob_map[d] } /
               dists.count
      end
      fail "shiiiiiit"
    end

  end
end
