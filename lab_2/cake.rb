# cake.rb — розрізання торта з родзинками (лаконічно + нумерований вивід)

def cut_cake(lines)
  h = lines.size
  return [] if h == 0
  w = lines.first.size
  return [] unless lines.all? { |row| row.size == w }

  grid = lines.map(&:chars)
  is_rais = ->(ch){ ch == 'o' || ch == 'о' } # лат/кир 'o'

  raisins = []
  h.times { |r| w.times { |c| raisins << [r,c] if is_rais.call(grid[r][c]) } }
  n = raisins.size
  return [] if n < 2 || n >= 10

  total = h * w
  return [] unless total % n == 0
  area = total / n

  used = Array.new(h) { Array.new(w, false) }

  rects = []
  1.upto(w) do |rw|
    next unless area % rw == 0
    rh = area / rw
    next if rh > h
    rects << [rw, rh]
  end
  rects.sort_by! { |rw, rh| [-rw, -rh] } # найширші спершу

  pieces = []

  count_raisins = ->(r0, c0, rw, rh) do
    cnt = 0
    r0.upto(r0+rh-1) do |r|
      c0.upto(c0+rw-1) do |c|
        cnt += 1 if is_rais.call(grid[r][c])
        return 2 if cnt > 1
      end
    end
    cnt
  end

  overlap_at = ->(r0, c0, rw, rh) do
    r0.upto(r0+rh-1) do |r|
      c0.upto(c0+rw-1) { |c| return true if used[r][c] }
    end
    false
  end

  mark = ->(r0, c0, rw, rh, val) do
    r0.upto(r0+rh-1) { |r| c0.upto(c0+rw-1) { |c| used[r][c] = val } }
  end

  extract = ->(r0, c0, rw, rh) do
    (r0...(r0+rh)).map { |r| grid[r][c0, rw].join }
  end

  next_free = -> do
    h.times { |r| w.times { |c| return [r,c] unless used[r][c] } }
    nil
  end

  dfs = lambda do
    cell = next_free.call
    return true if cell.nil?
    r0, c0 = cell

    rects.each do |rw, rh|
      next if r0 + rh > h || c0 + rw > w
      next if overlap_at.call(r0, c0, rw, rh)
      next unless count_raisins.call(r0, c0, rw, rh) == 1

      mark.call(r0, c0, rw, rh, true)
      pieces << extract.call(r0, c0, rw, rh)

      return true if dfs.call

      pieces.pop
      mark.call(r0, c0, rw, rh, false)
    end
    false
  end

  dfs.call ? pieces : []
end

# -------- Нумерований красивий вивід --------
def print_pieces_numbered(title, pieces)
  puts title
  pieces.each_with_index do |p, i|
    puts "Шматок ##{i+1}:"
    p.each { |row| puts row }
    puts
  end
end

# -------- Приклади --------
if __FILE__ == $PROGRAM_NAME
  cake1 = [
    "........",
    "..o.....",
    "...o....",
    "........"
  ]
  cake2 = [
    ".о......",
    "......о.",
    "....о...",
    "..о....."
  ]
  cake3 = [
    ".o.o....",
    "........",
    "....o...",
    "........",
    ".....o..",
    "........"
  ]

  print_pieces_numbered("Cake1:", cut_cake(cake1))
  print_pieces_numbered("Cake2:", cut_cake(cake2))
  print_pieces_numbered("Cake3:", cut_cake(cake3))
end
