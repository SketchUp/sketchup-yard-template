require './tools/thor/config'
require './tools/thor/yard_helper'

class Stubs < Thor

  include Thor::Actions
  include ConfigHelper
  include YardHelper

  desc "make", "Generate stubs for the Ruby API"
  yard_method_options
  def make
    command = yard_command("yardoc -t stubs -f text")
    command.exec
  end
  default_task :make

  desc "install", "Installs the stubs to configured target folder"
  def install
    unless config?(:stubs, :target)
      puts "ERROR: Stubs target install path not set."
      exit
    end
    source = 'stubs/.'
    target = read_config(:stubs, :target)
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
    directory('assets', "#{target}/assets", force: true)
    directory('pages', "#{target}/pages", force: true)
    directory('su-template/default', "#{target}/su-template/default", force: true)
    create_file("#{target}/.yardopts", force: true) {
      <<-EOT
--title "SketchUp Ruby API Documentation"
--no-api
--no-private
-p su-template
SketchUp/**/*.rb
-
pages/*.md
      EOT
    }
  end

  desc "configure TARGET_PATH", "Configure install path for the stubs"
  def configure(target_path)
    unless File.directory?(target_path)
      puts "ERROR: Target path does not exist: #{target_path}"
      exit
    end
    write_config(:stubs, :target, target_path)
  end
  default_task :make

end
