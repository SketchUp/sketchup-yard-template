# Script to generate the Error class name map in:
# lib\yard-sketchup\patches\c_base_handler.rb

require 'open-uri'

url = 'https://raw.githubusercontent.com/ruby/ruby/ruby_2_5/error.c'

INIT_MATCH = /void\s+Init_Exception\(void\)\s*\{(.+?)^\}/m
NAME_MATCH = /(\w+)\s*=\s*rb_define_class\("([^"]+)"/

$stderr.puts "Downloading #{url} ..."
content = open(url) { |io| io.read }

$stderr.puts "Extracting class names ..."
init_content = content.match(INIT_MATCH).captures.first

puts '{'
init_content.scan(NAME_MATCH).each do |variable, name|
  puts "  '#{variable}' => '#{name}',"
end
puts '}'
