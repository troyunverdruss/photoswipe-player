#!/usr/bin/env ruby

require 'optparse'
require 'fileutils'
require 'pathname'

pathname = Pathname.new __dir__

options = {}
options[:template_path] = pathname.parent.to_s

OptionParser.new do |opts|
  opts.banner = "Usage: ./process-image.rb"

  opts.on '-h', '--help', 'Help' do |h|
    options[:help] = h
  end
end

unless Dir.exist? 'img'
  Dir.mkdir 'img'
end

unless Dir.exist? 'thumbs'
  Dir.mkdir 'thumbs'
end

FileUtils.mv Dir.glob('./*jpg'), 'img/'

if File.exist? '/index.template.html'
  FileUtils.rm '/index.template.html'
end
FileUtils.cp_r options[:template_path] + '/index.template.html', './'

if File.exist? '/res/'
  FileUtils.rm_r '/res/'
end
FileUtils.cp_r options[:template_path] + '/res/', './'

image_lines = []
image_data = []
data_index = 0
Dir.glob 'img/*.jpg' do |pic|
  name = File.basename(pic)

  width = `identify -format "%w" #{pic}`.chomp
  height = `identify -format "%h" #{pic}`.chomp

  `mogrify -resize x200 -format jpg -quality 75 -path thumbs #{pic}`

  width_t = `identify -format "%w" thumbs/#{name}`.chomp
  height_t = `identify -format "%h" thumbs/#{name}`.chomp

  image_data.push "{src: \"#{pic}\", w: #{width}, h: #{height}}"

  image_lines.push '<figure itemprop="associatedMedia">'
  image_lines.push "  <a href=\"#{pic}\" itemprop=\"contentUrl\" data-size=\"#{width}x#{height}\" data-index=\"#{data_index}\">"
  image_lines.push "    <img class=\"lazy thumbnail\" data-original=\"thumbs/#{name}\" height=\"#{height_t}\" width=\"#{width_t}\" itemprop=\"thumbnail\" alt=\"\">"
  image_lines.push '  </a>'
  image_lines.push '</figure>'

  data_index += 1
end

template_file = []
File.open 'index.template.html', 'r' do |f|
  f.each_line do |l|
    template_file.push l
  end
end

File.open 'index.html', 'w' do |f|
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

if File.exist? 'index.template.html'
  FileUtils.rm 'index.template.html'
end