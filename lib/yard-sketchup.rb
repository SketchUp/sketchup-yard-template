require 'yard'
require 'yard-sketchup/version'
require 'yard-sketchup/stubs/autoload'
require 'yard-sketchup/yard/logger'
require 'yard-sketchup/yard/handlers/class_constants'
require 'yard-sketchup/yard/handlers/class_enum_constants'
require 'yard-sketchup/yard/handlers/global_constants'
require 'yard-sketchup/patches/c_base_handler'

module SketchUpYARD

  def self.init
    # https://github.com/burtlo/yard-cucumber/blob/master/lib/yard-cucumber.rb
    # This registered template works for yardoc
    # YARD::Templates::Engine.register_template_path File.dirname(__FILE__) + '/templates'
    # The following static paths and templates are for yard server
    # YARD::Server.register_static_path File.dirname(__FILE__) + "/templates/default/fulldoc/html"

    YARD::Templates::Engine.register_template_path self.templates_path

    # https://www.rubydoc.info/gems/yard/file/docs/TagsArch.md#Adding_Custom_Tags
    # https://github.com/lsegal/yard/issues/1227
    # Custom visible tags:
    tags = [
      YARD::Tags::Library.define_tag('Known Bugs', :bug),
    ]
    YARD::Tags::Library.visible_tags |= tags

    # Custom directive tags:
    YARD::Tags::Library.define_tag('Category', :category, :with_title_and_text)
    YARD::Tags::Library.transitive_tags << :category
  end

  def self.templates_path
    File.join(__dir__, 'yard-sketchup', 'templates')
  end

end

SketchUpYARD.init
