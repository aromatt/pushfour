require_relative 'board'

module PushFour
  class Strategy

    attr_accessor :board, :player
    attr_reader :timing

    def initialize(board, player)
      fail unless board && player
      @board = board
      @player = player
      @timing = {}

    end

    # Returns all positions in win paths for both players
    def get_candidates(player = @player, b = @board)
      debug = false
      @timing[:get_candidates] ||= 0
      start_time = Time.now
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

      # TODO
      fail "nil candidate: #{candidates}" if candidates.any? {|c| c.nil?}

      candidates.uniq
    end

    # TODO
    def opponent(player = @player)
      return 'r' if player == 'b'
      return 'b' if player == 'r'
      nil
    end

  end
end
