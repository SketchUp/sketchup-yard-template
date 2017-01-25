require 'json'

module ConfigHelper

  CONFIGURATION_FILENAME = 'config.json'.freeze

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
