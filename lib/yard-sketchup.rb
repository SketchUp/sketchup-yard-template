require 'yard'
require 'yard-sketchup/version'
require 'yard-sketchup/yard/logger'
require 'yard-sketchup/yard/handlers/class_constants'
require 'yard-sketchup/yard/handlers/class_enum_constants'
require 'yard-sketchup/yard/handlers/global_constants'

module SketchUpYARD

  def self.init
    # https://github.com/burtlo/yard-cucumber/blob/master/lib/yard-cucumber.rb
    # This registered template works for yardoc
    # YARD::Templates::Engine.register_template_path File.dirname(__FILE__) + '/templates'
    # The following static paths and templates are for yard server
    # YARD::Server.register_static_path File.dirname(__FILE__) + "/templates/default/fulldoc/html"

    YARD::Templates::Engine.register_template_path self.templates_path
  end

  def self.templates_path
    File.join(__dir__, 'templates')
  end

end

SketchupYARD.init
