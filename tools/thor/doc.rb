require './tools/thor/config'
require './tools/thor/yard_helper'

class Doc < Thor

  include Thor::Actions
  include ConfigHelper
  include YardHelper

  desc "make", "Build Ruby API documentation"
  yard_method_options
  def make
    command = yard_command("yardoc")
    command.exec
  end
  default_task :make

  desc "undocumented", "List undocumented Ruby API features"
  yard_method_options
  def undocumented
    command = yard_command("yard stats --list-undoc")
    command.exec
  end

  desc "versions", "Lists all known SketchUp versions in the Ruby API "
  yard_method_options
  def versions
    command = yard_command("yardoc -t versions -f text")
    command.exec
  end

  desc "install", "Installs the docs to configured target folder"
  def install
    unless config?(:docs, :target)
      puts "ERROR: Stubs target install path not set."
      exit
    end
    source = 'doc/.'
    target = read_config(:docs, :target)
    destination_root = target
    source_paths << Dir.pwd
    puts "Source: #{source}"
    puts "Target: #{target}"
    unless File.writable?(target)
      puts ""
      puts "FAILURE"
      puts "Target path not writable."
      exit
    end
    # TODO(thomthom): Clean out target to eliminate removed files?
    FileUtils.cp_r(source, target)
  end

  desc "configure TARGET_PATH", "Configure install path for the docs"
  def configure(target_path)
    unless File.directory?(target_path)
      puts "ERROR: Target path does not exist: #{target_path}"
      exit
    end
    write_config(:docs, :target, target_path)
  end
  default_task :make

end
