module PushFour

  BLUE_CHAR  = 'b'
  RED_CHAR   = 'r'
  ROCK_CHAR  = '#'
  EMPTY_CHAR = '+'

  class Board

    attr_accessor :rows, :columns, :win_len, :cache
    attr_reader :board_string # arbitrarily setting this would break cache

    @@timing = Hash.new { |h,k| h[k] = 0 }
    @@calls = Hash.new { |h,k| h[k] = 0 }

    # Measures how many times we used cache vs not
    @@caching = Hash.new { |h,k| h[k] = { cached: 0, non: 0 } }

    @@perms_cache = {}
    @@neighbors_cache = {}

    def self.caching
      @@caching
    end

    def self.timing
      @@timing
    end

    def self.calls
      @@calls
    end

    # TODO test!
    def dup(string = nil)
      Board.new(
        @rows,
        @columns,
        @win_len,
        string || @board_string.dup,
        cache: @cache.dup
      )
    end

    def initialize(rows = 8, columns = 8, win_len = 4, init_string = nil, opts = {})
      @win_len = win_len
      @rows = rows
      @columns = columns

      if init_string
        init_string.gsub!(/[^rb#\+]|/, '')
        if init_string.length != @rows * @columns
          fail "init board string must contain #{@rows} * #{@columns} chars"
        else
          @board_string = init_string
        end
      else
        @board_string ||= '+' * (rows * columns)
      end

      @cache = opts[:cache] || Hash.new { |h,k| h[k] = {} }
    end

    def flush_cache
      #puts "flushing cache"
      @cache[:path] = {}
      #@cache[:find_move] = {}
      #@cache[:try_move] = {}
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
      new_pos = try_move(side, channel)
      if new_pos
        flush_cache
        @board_string[new_pos] = player
        invalidate_move_cache(new_pos)
        return new_pos
      else
        return false
      end
    end

    # returns new board with move applied
    def apply_move(player, side, channel)
      new_pos = try_move(side, channel)
      if new_pos
        string = @board_string.dup
        string[new_pos] = player
        b = Board.new(
          @rows,
          @columns,
          @win_len,
          string
        )
        b.flush_cache
        b.invalidate_move_cache(new_pos)
        #b = self.dup(string)
        return b
      else
        #puts "returning false from apply_move"
        return false
      end
    end

    def board_string_write(pos, player)
      @board_string[pos] = player
      invalidate_move_cache(pos)
    end

    # use this whenever
    def invalidate_move_cache(pos)
      col = column_of pos
      row = row_of pos

      [:right, :left].each do |side|
        @cache[:try_move][[side, row]] = nil
      end
      [:top, :bottom].each do |side|
        @cache[:try_move][[side, col]] = nil
      end
      row_offset = @columns * row
      @columns.times do |i|
        @cache[:find_move][i + row_offset] = nil
      end
      @rows.times do |i|
        @cache[:find_move][col + i * @columns] = nil
      end
    end

    # returns the resulting position of the move, or false if the move is impossible
    def try_move(side, channel)
      start_time = Time.now
      @@calls[:try_move] += 1
      dir_map = {
        left: [channel * @columns, 1],
        right: [(channel + 1) * @columns - 1, -1],
        bottom: [channel + @columns * (rows - 1), -@columns],
        top: [channel, @columns]
      }
      cached = @cache[:try_move][[side, channel]]
      if cached
        @@timing[:try_move] += Time.now - start_time
        return cached
      end

      #puts "trying move (#{side}, #{channel})"
      start, dir = dir_map[side]

      if pos_occupied? start
        @@timing[:try_move] += Time.now - start_time
        @cache[:try_move][[side, channel]] = false
        return false
      end

      cur_pos = start
      next_pos = start + dir
      loop do
        break unless pos_on_board?(next_pos) && !pos_occupied?(next_pos)
        dx, dy = xy_delta(cur_pos, next_pos)
        break if dx.abs > 1 || dy.abs > 1
        cur_pos = next_pos
        next_pos += dir
      end
      @@timing[:try_move] += Time.now - start_time
      @cache[:try_move][[side, channel]] = cur_pos
    end

    def winner
      ['r', 'b'].each do |player|
        return player if won? player
      end
      nil
    end

    def won?(player)
      poses_for(player).each do |pos|
        return true if unocc_win_masks(pos, player).any? do |mask|
          mask & get_bitmask(player) == mask
        end
      end
      false
    end

    def done?
      return true if winner
      return true if random_move.nil?
      false
    end

    def unocc_win_masks(pos, player)
      raw = raw_win_masks(pos)
      occ_symbols = ['#', 'r', 'b'] - [player]
      occ_mask = occ_symbols.reduce(0) do |a, sym|
        a | get_bitmask(sym)
      end
      raw.reject! { |w| w & occ_mask > 0 }
      raw
    end

    # valid wins for a particular pos and player
    def valid_wins(pos, player)
      unocc = unocc_win_masks(pos, player).map { |w| mask_to_pos(w) }
      unocc.reject do |win|
        paths = win.reject { |pos| @board_string[pos] == player }.map { |pos| find_path(pos) }
        paths.any?(&:nil?)
      end
    end

    def valid_win_pathsets(pos, player)
      debug = false
      @@calls[:valid_win_pathsets] += 1
      start_time = Time.now

      unocc_wins = unocc_win_masks(pos, player).map { |w| mask_to_pos(w) }
      pathsets = []
      puts "valid_win_pathsets for #{[pos, player]}: unocc_wins: #{unocc_wins.inspect}" if debug
      unocc_wins.each do |win|
        pathset = nil

        # don't need to find paths to positions that we already have
        no_self = win.reject { |pos| @board_string[pos] == player }
        puts " win: #{no_self}" if debug

        # find a path to each position in the win
        pathset = []
        b_temp = self.dup # TODO optimize
        poses_in_paths = []
        valid = true
        no_self.each do |pos|
          path = b_temp.find_path(pos)
          if path.nil?
            valid = false
            break
          end
          path.reject! { |pos| poses_in_paths.include? pos }
          poses_in_paths += path
          pathset << path
          b_temp.board_string_write(pos, player)
        end

        next unless valid

        # don't add wins with unreachable positions
        next if pathset.nil? || pathset.any?(&:nil?)

        # don't add superwins (new pathset is a superset of an existing one)
        next if pathsets.any? do |existing|
          pathset.flatten.sort[0..existing.count - 1] == existing.flatten.sort
        end

        puts "  adding pathset #{pathset.inspect}" if debug
        pathsets << pathset
      end
      @@timing[:valid_win_pathsets] += Time.now - start_time
      pathsets
    end

    # provide a bit-string position
    # returns array of masks representing wins containing <pos>
    #
    def raw_win_masks(pos)
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
        poses = mask_to_pos(w)
        poses.count < @win_len || !contiguous?(poses)
      end
    end

    # returns bit-string positions
    def mask_to_pos(mask)
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

    def pos_to_mask(pos)
      pos.inject(0) { |a, p|  a | (1 << p) }
    end

    def xy_to_pos(x, y)
      pos = x + y * @columns
    end

    # returns [] of symbols from {:left, :right, :top, :bottom}
    def touching_edges(pos)
      edges = []
      row = row_of(pos)
      col = column_of(pos)
      edges << :top if row == 0
      edges << :bottom if row == @rows - 1
      edges << :left if col == 0
      edges << :right if col == @columns - 1
      edges
    end

    # return a shortest path from some neighbor or edge to pos
    # return nil if occupied or unreachable
    #
    # TODO 1) copy cache when creating copies of boards, because copies are used a lot
    #      2) instead of flushing cache when board string changes, invalidate intelligently
    #
    def find_path(pos)
      debug = false
      puts "finding path to #{pos}" if debug
      @@calls[:find_path] += 1
      start_time = Time.now
      start = 0
      if pos_occupied? pos
        return nil
      end

      if @cache[:path][pos]
        @@caching[:find_path][:cached] += 1
        @@timing[:find_path] += Time.now - start_time
        return @cache[:path][pos].dup
      end

      @@caching[:find_path][:non] += 1

      # next to any edges? then check those first
      edges = touching_edges(pos)
      edges.each do |edge|
        puts "edge #{edge}" if debug
        side = opposite_side(edge)
        channel = get_channel(pos, side)
        return_val = [pos] if try_move(side, channel) == pos
        return return_val if return_val
      end
      puts " no edges worked" if debug

      # Not next to an edge; find a path from the closest neighbor.
      # Consider both occupied neighbors and unoccupied neighbors on edges
      dist = 1
      loop do
        neighbors = neighbors_at_dist(pos, dist)
        paths_to_try = []

        free_neighbors = (neighbors - mask_to_pos(occupied_mask))
        occ_neighbors = neighbors - free_neighbors

        # Try building off of occupied positions
        puts " in find path, occ_neighbors at dist #{dist} are #{occ_neighbors}" if debug
        occ_neighbors.each do |n|
          paths_to_try += raw_shortest_paths(n, pos).map { |p| p.shift; p }
        end

        # Try building off free neighbors on edges
        puts " in find path, free_neighbors at dist #{dist} are #{free_neighbors}" if debug
        free_neighbors.each do |n|
          if touching_edges(n)
            paths_to_try += raw_shortest_paths(n, pos)
          end
        end

        # Try all the paths we could find at this dist
        #b_temp = Board.new(@rows, @columns, @win_len, @board_string.dup)
        paths_to_try.each do |path|
          #b_temp.board_string = self.board_string.dup
          if valid_path? path
            @cache[:path][pos] = path.dup
            @@timing[:find_path] += Time.now - start_time
            return path.dup
          end
        end

        # Could not find a path at this distance, try farther out
        dist += 1
        break if dist == [@rows, @columns].max
      end # loop do (incr dist)

      @@timing[:find_path] += Time.now - start_time
      nil
    end

    def valid_path?(path, b_temp = nil)
      debug = false
      @@calls[:valid_path?] += 1
      start_time = Time.now
      b_temp ||= self.dup

      valid = true
      puts "valid path? #{path.inspect}" if debug
      path.each do |step|
        move = b_temp.find_move(step)
        puts " move: #{move}" if debug
        valid &&= move && b_temp.apply_move!('#', *move)
        unless valid
          puts "  step #{step} invalid; breaking" if debug
          break
        end
      end # each step

      @@timing[:valid_path?] += Time.now - start_time
      return valid
    end

    # Returns an array of paths (which are each an array of positions)
    # Does not consider if paths consist entirely of valid moves, but
    # does consider obstructions
    def raw_shortest_paths(start, finish)
      @@calls[:raw_shortest_paths] += 1


      start_time = Time.now
      x, y = xy_delta(start, finish)
      x_d = (x >= 0 ? 1 : - 1)
      y_d = (y >= 0 ? 1 : - 1)

      paths = []
      perms = []
      if @@perms_cache[[x.abs, y.abs]]
        perms = @@perms_cache[[x.abs, y.abs]]
      else
        perms = ([:x] * x.abs + [:y] * y.abs).permutation.to_a.uniq
        @@perms_cache[[x.abs, y.abs]] = perms
      end
      perms.each do |perm|
        puts "perm: #{perm}" if @debug
        path = [start]
        valid = true
        perm.each do |dir|
          next_pos = nil
          if dir == :x
            next_pos = apply_delta(path.last, x_d, 0)
          else
            next_pos = apply_delta(path.last, 0, y_d)
          end
          if pos_occupied? next_pos
            puts "path is obstructed!" if @debug
            valid = false
            break
          else
            path << next_pos
          end
        end
        puts "adding path: #{path.inspect}" if @debug
        paths << path if valid
      end
      @@timing[:raw_shortest_paths] += Time.now - start_time
      paths
    end

    # returns a list of positions (will be empty if none)
    #
    def neighbors_at_dist(pos, dist)
      puts "neighbors of pos #{pos}, dist #{dist}" if @debug
      start_time = Time.now
      @@calls[:neighbors_at_dist] += 1
      cached = @@neighbors_cache[[pos, dist]]
      if cached
        @@caching[:neighbors_at_dist][:cached] += 1
        @@timing[:neighbors_at_dist] += Time.now - start_time
        return cached
      end

      # TODO calculate these more efficiently?

      neighbors = []
      dist.times do |a|
        b = dist - a

        neighbors << apply_delta(pos, a, b)
        neighbors << apply_delta(pos, -b, a)
        neighbors << apply_delta(pos, -a, -b)
        neighbors << apply_delta(pos, b, -a)
      end
      @@caching[:neighbors_at_dist][:non] += 1
      @@timing[:neighbors_at_dist] += Time.now - start_time
      res = neighbors.compact
      @@neighbors_cache[[pos, dist]] = res
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

    def opposite_side(side)
      {left: :right, right: :left, top: :bottom, bottom: :top}[side]
    end

    # a and b are contiguous positions.
    # e.g., a = 0, b = 1, #=> :right
    def direction_to(a, b)
      fail "#{[a, b]} not contiguous!" unless contiguous?([a, b])
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
    def all_moves
      moves = {}
      (0...@columns).each do |chan|
        [:top, :bottom].each do |side|
          tried = try_move(side, chan)
          moves[[side, chan]] = tried if tried
        end
      end
      (0...@rows).each do |chan|
        [:left, :right].each do |side|
          tried = try_move(side, chan)
          moves[[side, chan]] = tried if tried
        end
      end
      moves
    end

    # returns a move that will get a piece into pos.
    # a move is a side (e.g. :left) and channel to get a piece into <pos>
    #
    def find_move(pos)
      debug = false
      puts "  finding move to #{pos}" if debug

      @@calls[:find_move] += 1
      start_time = Time.now

      if @cache[:find_move][pos]
        @@timing[:find_move] += Time.now - start_time
        @@caching[:find_move][:cached] += 1
        return @cache[:find_move][pos].dup
      end
      @@caching[:find_move][:non] += 1

      edges = touching_edges(pos)

      # If a position is next to an edge, try that first
      if edges.any?
        edges.each do |e|
          side = opposite_side(e)

          channel = get_channel(pos, side)
          if pos == try_move(side, channel)
            move = [side, channel]
            @cache[:find_move][pos] = move.dup
            @@timing[:find_move] += Time.now - start_time
            return move
          end
        end
      end

      neighbors = neighbors_at_dist(pos, 1)
      if neighbors.any?
        neighbors.each do |n|

          # get direction from neighbor to pos, e.g. :left
          side = direction_to(n, pos)
          puts "    in find_move, neighbor, pos: #{n}, #{pos}" if debug

          # TODO remove
          unless get_channel(pos, side) == get_channel(n, side)
            fail "neighbor and pos not in same channel"
          end

          channel = get_channel(pos, side)
          puts "    in find_move, channel: #{channel}, side: #{side}" if debug

          if pos == try_move(side, channel)
            @@timing[:find_move] += Time.now - start_time
            move = [side, channel]
            @cache[:find_move][pos] = move.dup
            return move
          end
        end
      end
      @@timing[:find_move] += Time.now - start_time
      nil
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

    def pos_occupied?(pos)
      #puts "Determining if #{pos} is occupied. value of pos in board_string is #{@board_string[pos]}"
      fail "pos #{pos} not on board" unless pos_on_board? pos
      @board_string[pos] != '+'
    end

    def random_move
      empty_pos.shuffle.each do |pos|
        move = find_move pos
        return move if move
      end
      nil
    end

    def num_empty
      @board_string.count('+')
    end

    def empty_mask
      get_bitmask(EMPTY_CHAR)
    end

    def occupied_mask
      blue_mask | red_mask | rock_mask
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

    def blue_pos
      mask_to_pos(get_bitmask(BLUE_CHAR))
    end

    def red_pos
      mask_to_pos(get_bitmask(RED_CHAR))
    end

    def rock_pos
      mask_to_pos(get_bitmask(ROCK_CHAR))
    end

    def empty_pos
      mask_to_pos(get_bitmask(EMPTY_CHAR))
    end

    def poses_for(player)
      mask_to_pos(get_bitmask(player))
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
      @board_string.chars.to_a.reverse.inject(0) do |a,c|
        (a << 1) + (c == char ? 1: 0)
      end
    end

    def add_rock!(pos)
      @board_string[pos] = ROCK_CHAR
    end

    def add_random_rocks!(num_rocks = nil)
      num_rocks ||= Math.sqrt(rows * columns).to_i / 2

      num_rocks.times do
        add_rock! Random.rand(@board_string.length)
      end
    end

  end

end
