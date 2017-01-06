require 'fileutils'

require './tools/thor/yard_helper'

class Coverage < Thor

  include YardHelper

  MANIFEST_FILENAME = 'coverage.manifest'.freeze

  desc "make", "Generating TestUp coverage.manifest for the Ruby API"
  yard_method_options
  def make
    command = yard_command("yardoc -t coverage -f text")
    command.exec
  end
  default_task :make

  desc "install", "Installs the manifest to the tests folder"
  def install
    source_path = Dir.pwd
    target_path = File.join(Dir.pwd, "../tests/SketchUp Ruby API")
    target_path = File.expand_path(target_path)
    source_file = File.join(source_path, MANIFEST_FILENAME)
    target_file = File.join(target_path, MANIFEST_FILENAME)
    puts "Source: #{source_file}"
    puts "Target: #{target_file}"
    unless File.writable?(target_file)
      puts ""
      puts "FAILURE"
      puts "Target file not writable. Remember to check it out in P4 first."
      exit
    end
    FileUtils.cp(source_file, target_path)
  end

end
