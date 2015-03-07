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

    # TODO
    def opponent(player = @player)
      return 'r' if player == 'b'
      return 'b' if player == 'r'
      nil
    end

  end
end
