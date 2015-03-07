module PushFour


  module BoardLight
    BLUE_CHAR  = 'b'
    RED_CHAR   = 'r'
    ROCK_CHAR  = '#'
    EMPTY_CHAR = '+'
    WIN_LEN = 4

    def picture(board, rows, cols)
      string = board.dup
      (1..rows).reverse_each do |row|
        string.insert(row * cols, "\n")
      end
      string
    end

    # move valid: modify board and return true
    # move invalid: return false
    def apply_move!(board, rows, cols, player, side, channel)
      new_pos = try_move(board, rows, cols, side, channel)
      if new_pos
        board[new_pos] = player
        return true
      else
        return false
      end
    end

    # returns the resulting position of the move, or false if the move is impossible
    def try_move(board, rows, cols, side, channel)
      dir_map = {
        left: [channel * cols, 1],
        right: [(channel + 1) * cols - 1, -1],
        bottom: [channel + cols * (rows - 1), -cols],
        top: [channel, cols]
      }
      start, dir = dir_map[side]
      if pos_occupied?(board, rows, cols, start)
        return false
      end

      cur_pos = start
      next_pos = start + dir
      loop do
        break unless pos_on_board?(rows, cols, next_pos) &&
          !pos_occupied?(board, rows, cols, next_pos)
        dx, dy = xy_delta(rows, cols, cur_pos, next_pos)
        break if dx.abs > 1 || dy.abs > 1
        cur_pos = next_pos
        next_pos += dir
      end
      cur_pos
    end

    def winner(board, rows, cols)
      ['r', 'b'].each do |player|
        return player if won?(board, rows, cols, player)
      end
      nil
    end

    def won?(board, rows, cols, player)
      poses_for(board, rows, cols, player).each do |pos|
        return true if unocc_win_masks(board, rows, cols, pos, player).any? do |mask|
          mask & get_bitmask(board, player) == mask
        end
      end
      false
    end

    def done?(board, rows, cols)
      return true if winner(board, rows, cols)
      # TODO try all moves
      false
    end

    def unocc_win_masks(board, rows, cols, pos, player)
      raw = raw_win_masks(rows, cols, pos)
      occ_symbols = ['#', 'r', 'b'] - [player]
      occ_mask = occ_symbols.reduce(0) do |a, sym|
        a | get_bitmask(board, sym)
      end
      raw.reject! { |w| w & occ_mask > 0 }
      raw
    end

    # provide a bit-string position
    # returns array of masks representing wins containing <pos>
    #
    def raw_win_masks(rows, cols, pos)
      wins = []

      [
        1,        # horizontal
        cols,     # vertical
        cols + 1, # /
        cols - 1  # \
      ].each do |period|
        mask = 0
        WIN_LEN.times { |i| mask |= (1 << (i * period)) }
        WIN_LEN.times do |i|
          new_mask = (mask << (pos - (WIN_LEN - 1 - i) * period))
          wins << new_mask
        end
      end

      wins.reject do |w|
        poses = mask_to_pos(rows, cols, w)
        poses.count < WIN_LEN || !contiguous?(rows, cols, poses)
      end
    end

    # returns bit-string positions
    def mask_to_pos(rows, cols, mask)
      poses = []
      check_mask = 1
      (rows * cols).times do |i|
        if mask & check_mask > 0
          poses << i
        end
        check_mask <<= 1
      end
      poses
    end

    def pos_to_mask(pos)
      pos.inject(0) { |a, p|  a | (1 << p) }
    end

    def xy_to_pos(rows, cols, x, y)
      pos = x + y * cols
    end

    # returns [] of symbols from {:left, :right, :top, :bottom}
    def touching_edges(rows, cols, pos)
      edges = []
      row = row_of(pos)
      col = column_of(pos)
      edges << :top if row == 0
      edges << :bottom if row == rows - 1
      edges << :left if col == 0
      edges << :right if col == cols - 1
      edges
    end

    def picture_for_mask(rows, cols, mask)
      string = ''
      (cols * rows).times do |i|
        occ = (mask & (1 << i)) > 0
        string << (((mask & (1 << i)) > 0) ? '1' : '0')
        string << "\n" if column_of(i) == cols - 1
      end
      string
    end

    def row_of(rows, cols, pos)
      pos / cols
    end

    def column_of(rows, cols, pos)
      pos % cols
    end

    # positions is an array of bit-string positions
    def contiguous?(rows, cols, positions)
      c = true
      (positions.count - 1).times do |i|
        x, y = xy_delta(rows, cols, positions[i], positions[i + 1])
        return false if x.abs > 1 || y.abs > 1
      end
      return true
    end

    def opposite_side(side)
      {left: :right, right: :left, top: :bottom, bottom: :top}[side]
    end

    # a and b are contiguous positions.
    # e.g., a = 0, b = 1, #=> :right
    def direction_to(a, b)
      fail "#{[a, b]} not contiguous!" unless contiguous?(rows, cols, [a, b])
      fail "#{a} == #{b}!" if a == b

      if column_of(a) == column_of(b)
        return a < b ? :bottom : :top
      else
        return a < b ? :right : :left
      end
      fail
    end

    def get_channel(pos, side)
      channel = ([:left,:right].include? side) ? row_of(pos) : column_of(pos)
    end

    # Returns hash { move => pos, ... } where move is array [side, channel]
    def all_moves(board, rows, cols)
      moves = {}
      (0...cols).each do |chan|
        [:top, :bottom].each do |side|
          tried = try_move(board, rows, cols, side, chan)
          moves[[side, chan]] = tried if tried
        end
      end
      (0...rows).each do |chan|
        [:left, :right].each do |side|
          tried = try_move(board, rows, cols, side, chan)
          moves[[side, chan]] = tried if tried
        end
      end
      moves
    end

    # input: two bit-string positions
    # output: x and y deltas
    #
    def xy_delta(rows, cols, first, second)
      x = column_of(rows, cols, second) - column_of(rows, cols, first)
      y = row_of(rows, cols, second) - row_of(rows, cols, first)
      [x, y]
    end

    # Applies x and y to start and returns the resulting position
    # return nil if off board
    #
    def apply_delta(rows, cols, pos, x, y)
      puts "applying delta (#{x}, #{y}) to pos #{pos} which is at " \
           "#{column_of(rows, cols, pos)}, #{row_of(rows, cols, pos)}" if @debug

      unless xy_on_board?(rows, cols, column_of(rows, cols, pos) + x, row_of(rows, cols, pos) + y)
        return nil
      end

      result = pos + x + y * cols
      result
    end

    def pos_on_board?(rows, cols, pos)
      if (pos >= 0) && (pos < cols * rows)
        puts "#{pos} is on the board" if @debug
        return true
      else
        puts "#{pos} is not on the board" if @debug
        return false
      end
    end

    def xy_on_board?(rows, cols, x, y)
      puts "xy_on_board? #{x}, #{y}" if @debug
      ((0...cols).cover? x) && ((0...rows).cover? y)
    end

    def pos_occupied?(board, rows, cols, pos)
      #puts "Determining if #{pos} is occupied. value of pos in board_string is #{board[pos]}"
      fail "pos #{pos} not on board" unless pos_on_board?(rows, cols, pos)
      board[pos] != '+'
    end

    def num_empty(board)
      board.count('+')
    end

    def empty_mask
      get_bitmask(board, EMPTY_CHAR)
    end

    def occupied_mask(board)
      blue_mask(board) | red_mask(board) | rock_mask(board)
    end

    def blue_mask
      get_bitmask(board, BLUE_CHAR)
    end

    def red_mask
      get_bitmask(board, RED_CHAR)
    end

    def rock_mask
      get_bitmask(board, ROCK_CHAR)
    end

    def blue_pos
      mask_to_pos(rows, cols, get_bitmask(board, BLUE_CHAR))
    end

    def red_pos
      mask_to_pos(rows, cols, get_bitmask(board, RED_CHAR))
    end

    def rock_pos
      mask_to_pos(rows, cols, get_bitmask(board, ROCK_CHAR))
    end

    def empty_pos
      mask_to_pos(rows, cols, get_bitmask(board, EMPTY_CHAR))
    end

    def poses_for(board, rows, cols, player)
      mask_to_pos(rows, cols, get_bitmask(board, player))
    end

    def get_bitmask(board, char)
      board.chars.to_a.reverse.inject(0) do |a,c|
        (a << 1) + (c == char ? 1: 0)
      end
    end

    def add_rock!(board, pos)
      board[pos] = ROCK_CHAR
    end

    def add_random_rocks!(board, rows, cols, num_rocks = nil)
      num_rocks ||= Math.sqrt(rows * cols).to_i / 2

      num_rocks.times do
        add_rock! Random.rand(board.length)
      end
    end

  end
end
