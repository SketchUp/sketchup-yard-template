require 'json'

require './tools/thor/yard_helper'

class Stubs < Thor

  include YardHelper

  CONFIGURATION_FILENAME = 'config.json'.freeze

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

  desc "configure TARGET_PATH", "Configure install path for the stubs"
  def configure(target_path)
    unless File.directory?(target_path)
      puts "ERROR: Target path does not exist: #{target_path}"
      exit
    end
    write_config(:stubs, :target, target_path)
  end
  default_task :make

  private

  def config_filename
    File.join(Dir.pwd, CONFIGURATION_FILENAME)
  end

  def config?(section, key)
    return false unless File.exist?(config_filename)
    config = load_config
    config.key?(section) && config[section].key?(key)
  end

  def load_config
    JSON.parse(File.read(config_filename), symbolize_names: true)
  end

  def save_config(config)
    json = JSON.pretty_generate(config)
    File.write(config_filename, json)
  end

  def read_config(section, key, default_value = nil)
    config = load_config
    config[section][key] || default_value
  end

  def write_config(section, key, value)
    config = File.exist?(config_filename) ? load_config : {}
    config[section] ||= {}
    config[section][key] = value
    save_config(config)
  end

end
