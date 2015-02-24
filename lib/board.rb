module PushFour

  BLUE_CHAR = 'b'
  RED_CHAR  = 'r'
  ROCK_CHAR = '#'

  class Board

    attr_reader :rows, :columns, :board_string

    def initialize(rows = 8, columns = 8, init_string = nil)
      @rows = rows
      @columns = columns
      if init_string
        if init_string.gsub(/[^rb#\+]/, '').length != @rows * @columns
          fail "init board string must contain #{@rows} * #{@columns} chars"
        else
          @board_string = init_string
        end
      else
        puts 'pp'
        @board_string ||= '+' * (rows * columns)
        add_random_rocks!
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
    def apply_move(player, side, channel)
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

    def get_move(pos)

    end

    # input: two bit-string positions
    # output: x and y deltas
    #
    def xy_delta(first, second)
      x = (second % @columns - first % @columns )
      y = second / @columns - first / @columns
      [x, y]
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
