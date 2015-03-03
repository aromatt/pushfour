require_relative 'board'


# TODO
#      - sometimes you can block by moving to get in someone's way, but not
#        necessarily in one of their win paths
#        - actually, it sort of half does this - but need to make sure it
#          includes these in candidates
#      - log every game it plays
#      - search deeper on less certain branches of tree
#      - include diversity in power score (number of unique positions in
#        wins. ==> lots of ways to win? or bottleneck?
#      - consider how in control you are
#        - how many options does the opponent have


module PushFour
  class Strategy

    attr_accessor :board, :player
    attr_reader :timing

    def initialize(board, player)
      fail unless board && player
      @board = board
      @player = player
      @timing = {}

      @prob_map = refresh_prob_map
    end

    # TODO
    def opponent(player = @player)
      {'r' => 'b', 'b' => 'r'}[player]
    end

    def best_move(player = @player, generous = false)
      debug = false
      @timing[:best_move] ||= 0
      start_time = Time.now

      # if first move, consider all positions
      generous = true if @board.poses_for(player).count == 0

      @prob_map = refresh_prob_map
      candidates = generous ? @board.empty_pos : get_candidates(player)
      scored = []
      candidates.each do |c|
        puts "candidate #{c}" if debug

        move = @board.find_move(c)
        next unless move
        puts " found move for c: #{move}" if debug

        # try the move and see how the board looks after
        b_temp = @board.apply_move(player, *move)

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

      if sorted.any?
        @timing[:best_move] += Time.now - start_time
        return sorted.last[0]
      else
        # Didn't find any good candidates; expand search to all empty positions
        return best_move(player, true)
      end
    end

    def get_candidates(player = @player)
      debug = false
      @timing[:get_candidates] ||= 0
      start_time = Time.now
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
      @timing[:get_candidates] += Time.now - start_time
      # what TODO if there are no pieces on the board... include rocks?
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
        puts "cur_pos: #{cur_pos}" if debug
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
        puts " #{pathsets.count} pathsets" if debug
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
        puts " pathsets for #{cur_pos}" if debug
        pathsets.each do |pathset|
          puts "  pathset #{pathset.inspect}" if debug
          win_dist = pathset.flatten.uniq.count
          puts "   win_dist #{win_dist}" if debug
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

      @timing[:player_power] += Time.now - start_time
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
