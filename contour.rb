require('pry')
require('digest')

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

puts "Reading input data..."
input = {}
File.readlines("./input/#{ARGV[0]}").each_with_index do |line, j|
  line.split(" ").map(&:to_i).each_with_index do |val, i|
    next unless val > 0
    if input[val].nil?
      input[val] = { "#{j}:#{i}" => 1 }
    else
      input[val]["#{j}:#{i}"] = 1
    end
  end
end

puts "Processing contours..."
min = input.keys.min
max = input.keys.max
master_stroke_hash = {}
stroke_list = {}
(min..max-1).step(ARGV[1].to_i).each do |n|
  points = {}
  stroke_list[n] = []
  keys = input.keys.select { |x| x > n }
  keys.each do |key|
    points = points.merge(input[key])
  end
  visited = {}
  points.keys.each do |coord|
    ji = coord.split(":").map(&:to_i)
    coords = [
      [ji[0], ji[1]],
      [ji[0]-1, ji[1]-1],
      [ji[0]-1, ji[1]+1],
      [ji[0]+1, ji[1]-1],
      [ji[0]+1, ji[1]+1],
      [ji[0]+1, ji[1]],
      [ji[0]-1, ji[1]],
      [ji[0], ji[1]+1],
      [ji[0], ji[1]-1],
    ]
    coords.each do |j,i|
      next if !visited["#{j}:#{i}"].nil? || (!points["#{j}:#{i}"].nil? && coord != "#{j}:#{i}")
      visited["#{j}:#{i}"] = 1
      value = [
        points["#{j}:#{i}"].nil? ? 0 : 1,
        points["#{j}:#{i+1}"].nil? ? 0 : 1,
        points["#{j+1}:#{i+1}"].nil? ? 0 : 1,
        points["#{j+1}:#{i}"].nil? ? 0 : 1,
      ].join.to_i(2)
      next if strokes[value].(i, j).empty?
      stroke = strokes[value].(i, j).first
      stroke_hash = Digest::MD5.hexdigest("#{stroke}:#{j}:#{i}")
      if master_stroke_hash[stroke_hash].nil?
        stroke_list[n] << stroke
        master_stroke_hash[stroke_hash] = stroke
      end
      if strokes[value].(i, j).length == 2
        stroke = strokes[value].(i, j).last
        stroke_hash = Digest::MD5.hexdigest("#{stroke}:#{j}:#{i}")
        if master_stroke_hash[stroke_hash].nil?
          stroke_list[n] << stroke
          master_stroke_hash[stroke_hash] = stroke
        end
      end
    end
  end
  puts "#{n}/#{max-1}"
end

puts "Num strokes: #{stroke_list.values.flatten.count}"

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

puts "Stitching paths..."
paths_per_level = []
stroke_list.values.each do |strokes|
  path = []
  strokes.each do |stroke|
    path << { start: stroke[:start], end: stroke[:end], strokes: [stroke] }
  end
  paths_per_level << path
end

num_levels = paths_per_level.count
final_paths = []
paths_per_level.each_with_index do |paths, n|
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
  puts "#{n+1}/#{num_levels}"
end

puts "Num paths: #{final_paths.count}"

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

File.open("./output/#{ARGV[0]}.nc", "w+") do |f|
  f.puts(commands)
end