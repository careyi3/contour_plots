require('pry')

strokes = {
  0 => -> (x, y) { [] },
  1 => -> (x, y) { [{start: {x: x, y: y + 0.5}, end: {x: x + 0.5, y: y + 1}}] },
  2 => -> (x, y) { [{start: {x: x + 0.5, y: y + 1}, end: {x: x + 1, y: y + 0.5}}] },
  3 => -> (x, y) { [{start: {x: x, y: y + 0.5}, end: {x: x + 1, y: y + 0.5}}] },
  4 => -> (x, y) { [{start: {x: x + 0.5, y: y}, end: {x: x + 1, y: y + 0.5}}] },
  5 => -> (x, y) { strokes[2].call(x, y) + strokes[7].call(x, y) },
  6 => -> (x, y) { [{start: {x: x+0.5, y: y + 1}, end: {x: x + 0.5, y: y}}] },
  7 => -> (x, y) { [{start: {x: x, y: y + 0.5}, end: {x: x + 0.5, y: y}}] },
  8 => -> (x, y) { strokes[7].call(x, y) },
  9 => -> (x, y) { strokes[6].call(x, y) },
  10 => -> (x, y) { strokes[1].call(x, y) + strokes[4].call(x, y) },
  11 => -> (x, y) { strokes[4].call(x, y) },
  12 => -> (x, y) { strokes[3].call(x, y) },
  13 => -> (x, y) { strokes[2].call(x, y) },
  14 => -> (x, y) { strokes[1].call(x, y) },
  15 => -> (x, y) { strokes[0].call(x, y) },
}

input = []

# File.readlines("./in.txt").each do |line|
#   input << line.split(" ").map(&:to_i)
# end

input = [
 [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
 [1,1,1,1,1,1,1,1,1,1,2,1,1,1,1],
 [1,1,1,1,1,1,1,1,1,2,3,2,1,1,1],
 [1,1,1,1,1,1,1,1,2,3,4,3,2,1,1],
 [1,1,1,1,1,1,1,1,2,3,3,3,2,1,1],
 [1,1,1,1,1,1,1,1,2,2,2,2,2,1,1],
 [1,1,2,2,2,2,1,1,1,1,2,2,1,1,1],
 [1,2,3,3,2,2,1,1,1,1,2,2,1,1,1],
 [1,2,3,2,2,2,2,2,1,1,2,2,1,1,1],
 [1,1,2,2,1,2,2,2,2,2,2,2,2,1,1],
 [1,1,1,1,1,2,2,2,3,3,3,3,2,1,1],
 [1,1,1,1,1,1,2,3,4,4,4,3,2,2,1],
 [1,1,1,1,1,1,2,3,4,5,4,4,3,2,1],
 [1,1,1,1,1,1,2,3,3,4,4,3,3,2,1],
 [1,1,1,1,1,1,2,2,3,3,3,3,3,2,1],
 [1,1,1,1,1,1,1,2,2,2,2,2,2,1,1],
 [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
]

threshold = Array.new(input.length) { Array.new(input.first.length) {0} }
output = Array.new(input.length - 1) { Array.new(input.first.length - 1) {0} }

def process_cell(j, i, threshold, output)
  points = [
    (threshold[j][i]).abs,
    (threshold[j][i+1]).abs,
    (threshold[j+1][i+1]).abs,
    (threshold[j+1][i]).abs,
  ]

  output[j][i] = points.join.to_i(2)

  output
end

def reverse_strokes(strokes)
  strokes = strokes.reverse
  strokes.each do |stroke|
    old_start = stroke[:start]
    old_end = stroke[:end]

    stroke[:start] = old_end
    stroke[:end] = old_start
  end
  strokes
end

stroke_list = []
[1,25,50,75,100,125,150,175, 200, 225, 250].each do |n|

  output = Array.new(input.length - 1) { Array.new(input.first.length - 1) {0} }

  (0..input.length-1).each do |j|
    (0..input.first.length-1).each do |i|
      threshold[j][i] = input[j][i] > n ? 1 : 0
    end
  end
  (0..input.length-2).each do |j|
    (0..input.first.length-2).each do |i|
      output = process_cell(j, i, threshold, output)
    end
  end

  output.each_with_index do |row, j|
    row.each_with_index do |cell, i|
      next if strokes[cell].(i, j).empty?
  
      stroke_list << strokes[cell].(i, j).first
      if strokes[cell].(i, j).length == 2
        stroke_list << strokes[cell].(i, j).last
      end
    end
  end
end

paths = []
stroke_list.each do |stroke|
  paths << { start: stroke[:start], end: stroke[:end], strokes: [stroke] }
end

final_paths = []
current_path = paths.pop
while paths.length.positive?
  matched = false
  paths.each_with_index do |path, idx|
    if current_path[:end] == path[:start] 
      current_path[:end] = path[:end]
      current_path[:strokes] = current_path[:strokes] + path[:strokes]
      paths.delete_at(idx)
      matched = true
    elsif current_path[:start] == path[:end] 
      current_path[:start] = path[:start]
      current_path[:strokes] = path[:strokes] + current_path[:strokes]
      paths.delete_at(idx)
      matched = true
    elsif current_path[:end] == path[:end] 
      current_path[:end] = path[:start]
      current_path[:strokes] = current_path[:strokes] + reverse_strokes(path[:strokes])
      paths.delete_at(idx)
      matched = true
    elsif current_path[:start] == path[:start] 
      current_path[:start] = path[:end]
      current_path[:strokes] = reverse_strokes(path[:strokes]) + current_path[:strokes]
      paths.delete_at(idx)
      matched = true
    end
  end
  unless matched
    final_paths << current_path
    current_path = paths.pop
  end
  if paths.length.zero?
    final_paths << current_path
  end
end

final_paths = final_paths.sort_by { |x| x[:strokes].length }.reverse

commands = []
commands << "G90 G94"
commands << "G17"
commands << "G21"
commands << "G28 G91 Z0"
commands << "G90"
commands << "S5000 M3"
final_paths.each do |path|
  commands << "G0 F400"
  commands << "Z1"
  commands << "X#{path[:start][:x]} Y#{path[:start][:y]}"
  commands << "Z-0.4"
  commands << "G1 F100"
  path[:strokes].each do |stroke|
    commands << "X#{stroke[:end][:x]} Y#{stroke[:end][:y]}"
  end
end
commands << "G0 F400"
commands << "Z2"
commands << "G28 G91 Z0"
commands << "G90"
commands << "G28 G91 X0 Y0"
commands << "G90"
commands << "M5"
commands << "M30"

puts commands
