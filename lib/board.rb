module PushFour

  BLUE_CHAR = 'b'
  RED_CHAR  = 'r'
  ROCK_CHAR = '#'

  class Board

    attr_reader :rows, :columns, :board_string

    def initialize(rows = 8, columns = 8, win_len = 4, init_string = nil)
      @win_len = win_len
      @rows = rows
      @columns = columns
      if init_string
        if init_string.gsub(/[^rb#\+]/, '').length != @rows * @columns
          fail "init board string must contain #{@rows} * #{@columns} chars"
        else
          @board_string = init_string
        end
      else
        @board_string ||= '+' * (rows * columns)
      end
    end

    def board_picture
      string = @board_string.dup
      (1..@rows).reverse_each do |row|
        string.insert(row * @columns, "\n")
      end
      string
    end

    # player:  0 or 1
    # side:    :left, :right, :bottom, :top
    # channel: integer
    #
    # return false if invalid move
    #
    def apply_move!(player, side, channel)
      # TODO store this somewhere else
      dir_map = {
        left: [channel * @columns, 1],
        right: [(channel + 1) * @columns - 1, -1],
        bottom: [channel + @columns * (rows - 1), -@columns],
        top: [channel, @columns]
      }
      start, dir = dir_map[side]

      return false if pos_occupied? start
      cur_pos = start
      next_pos = start + dir
      loop do
        break unless pos_on_board?(next_pos) && !pos_occupied?(next_pos)
        dx, dy = xy_delta(cur_pos, next_pos)
        break if dx.abs > 1 || dy.abs > 1
        cur_pos = next_pos
        next_pos += dir
      end
      @board_string[cur_pos] =  player
      cur_pos
    end

    # provide a bit-string position
    # returns array of masks representing wins containing <pos>
    #
    def raw_wins_for(pos)
      wins = []

      [
        1,            # horizontal
        @columns,     # vertical
        @columns + 1, # /
        @columns - 1  # \
      ].each do |period|
        mask = 0
        @win_len.times { |i| mask |= (1 << (i * period)) }
        @win_len.times do |i|
          new_mask = (mask << (pos - (@win_len - 1 - i) * period))
          wins << new_mask
        end
      end

      wins.reject do |w|
        poses = positions_for(w)
        poses.count < @win_len || !contiguous?(poses)
      end
    end

    # returns bit-string positions
    def positions_for(mask)
      poses = []
      check_mask = 1
      (@rows * @columns).times do |i|
        if mask & check_mask > 0
          poses << i
        end
        check_mask <<= 1
      end
      poses
    end

    # search in an outward spiral for closest neighbor
    # return distance to closest neighbor (including edges of the board)
    def distance_to(pos)
      # next to an edge?
      if row_for(pos) == 0 || row_for(pos == @rows - 1) ||
        column_for(pos) == 0 || column_for(pos == @columns - 1)
        return 0
      end

    end

    # TODO should probably draw a border around the whole board
    def neighbors_at_dist(pos, dist)
      puts "neighbors of pos #{pos}, dist #{dist}" if @debug

      # TODO calculate these more efficiently

      neighbors = []
      dist.times do |a|
        b = dist - a

        neighbors << apply_delta(pos, a, b)
        neighbors << apply_delta(pos, -b, a)
        neighbors << apply_delta(pos, -a, -b)
        neighbors << apply_delta(pos, b, -a)
      end
      neighbors.compact
    end

    def picture_for_mask(mask)
      string = ''
      (@columns * @rows).times do |i|
        occ = (mask & (1 << i)) > 0
        string << (((mask & (1 << i)) > 0) ? '1' : '0')
        string << "\n" if column_of(i) == @columns - 1
      end
      string
    end

    def pos_to_mask(*pos)
      pos.inject(0) { |a, p|  a | (1 << p) }
    end

    def row_of(pos)
      pos / @columns
    end

    def column_of(pos)
      pos % @columns
    end

    # positions is an array of bit-string positions
    def contiguous?(positions)
      c = true
      (positions.count - 1).times do |i|
        x, y = xy_delta(positions[i], positions[i + 1])
        return false if x.abs > 1 || y.abs > 1
      end
      return true
    end

    # returns a move that will get a piece into pos.
    # a move is a side (e.g. :left) and channel to get a piece into <pos>
    #
    def get_move(pos)
      # TODO
    end

    # input: two bit-string positions
    # output: x and y deltas
    #
    def xy_delta(first, second)
      x = column_of(second) - column_of(first)
      y = row_of(second) - row_of(first)
      [x, y]
    end

    # Applies x and y to start and returns the resulting position
    # return nil if off board
    #
    def apply_delta(pos, x, y)
      puts "applying delta (#{x}, #{y}) to pos #{pos} which is at #{column_of pos}, #{row_of pos}" if @debug
      return nil unless xy_on_board?(column_of(pos) + x, row_of(pos) + y)
      result = pos + x + y * @columns
      result
    end

    def pos_on_board?(pos)
      if (pos >= 0) && (pos < @columns * @rows)
        puts "#{pos} is on the board" if @debug
        return true
      else
        puts "#{pos} is not on the board" if @debug
        return false
      end
    end

    def xy_on_board?(x, y)
      puts "xy_on_board? #{x}, #{y}" if @debug
      ((0...@columns).cover? x) && ((0...@rows).cover? y)
    end

    # TODO why not just check the board string?
    def pos_occupied?(pos)
      if ((1 << pos) & (blue_mask | red_mask | rock_mask)) > 0
        puts "#{pos} is occupied" if @debug
        return true
      else
        puts "#{pos} is open" if @debug
        return false
      end
    end

    def blue_mask
      get_bitmask(BLUE_CHAR)
    end

    def red_mask
      get_bitmask(RED_CHAR)
    end

    def rock_mask
      get_bitmask(ROCK_CHAR)
    end

    def move_mask(side, channel)
      mask = 0
      if [:left, :right].include? side
        @columns.times do |i|
          mask |= 1 << channel * @columns + i
        end
      else
        @rows.times do |i|
          mask |= 1 << channel + (@columns * i)
        end
      end
      mask
    end

    def get_bitmask(char)
      @board_string.chars.reverse.inject(0) do |a,c|
        (a << 1) + (c == char ? 1: 0)
      end
    end

    def add_random_rocks!(num_rocks = nil)

      num_rocks ||= Math.sqrt(rows * columns).to_i / 2

      num_rocks.times do
        pos = Random.rand(@board_string.length)
        @board_string[pos] = ROCK_CHAR
      end
    end

  end

end
