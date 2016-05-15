#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'

options = {}
options[:template] = '/Users/troy/Dropbox/photo-slide-show/photoswipe/'

OptionParser.new do |opts|
  opts.banner = "Usage: ./process-image.rb"

  opts.on("-h", "--help", "Help") do |h|
    options[:help]  = h
  end
end


Dir.mkdir 'img'
Dir.mkdir 'thumbs'

FileUtils.mv(Dir.glob('./*jpg'), 'img/')
FileUtils.cp_r(options[:template] + '/index.template.html', './')
FileUtils.cp_r(options[:template] + '/res/', './')

image_lines = []
image_data = []
data_index = 0
Dir.glob('img/*.jpg') do |pic|
  name = File.basename(pic)
  #puts "Processing image: #{pic}"

  width = `identify -format "%w" #{pic}`.chomp
  height = `identify -format "%h" #{pic}`.chomp

  `mogrify -resize x200 -format jpg -quality 75 -path thumbs #{pic}`

  width_t = `identify -format "%w" thumbs/#{name}`.chomp
  height_t = `identify -format "%h" thumbs/#{name}`.chomp

  image_data.push("{src: \"#{pic}\", w: #{width}, h: #{height}}")

  image_lines.push('<figure itemprop="associatedMedia">')
  image_lines.push("  <a href=\"#{pic}\" itemprop=\"contentUrl\" data-size=\"#{width}x#{height}\" data-index=\"#{data_index}\">")
  image_lines.push("    <img class=\"lazy\" data-original=\"thumbs/#{name}\" height=\"#{height_t}\" width=\"#{width_t}\" itemprop=\"thumbnail\" alt=\"\">")
  image_lines.push('  </a>')
  image_lines.push('</figure>')

  data_index += 1
end

template_file = []
File.open('index.template.html', 'r') do |f|
  f.each_line do |l|
    template_file.push(l)
  end
end

File.open('index.html', 'w') do |f|
  template_file.each do |i|
    if i.chomp =~ /\{\{REPLACE_WITH_IMAGE_DATA}}/
      image_lines.each do |data|
        f.puts data
      end
    else
      f.puts i.chomp
    end
  end
end
