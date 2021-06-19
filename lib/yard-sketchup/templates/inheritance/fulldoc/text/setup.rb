require 'set'

include Helpers::ModuleHelper

MANIFEST_FILENAME = 'coverage.manifest'.freeze

def init
  list_all_classes
end


def all_objects
  run_verifier(Registry.all)
end

def class_objects
  run_verifier(Registry.all(:class))
end

def namespace_definition(object)
  return if object.root?
  definition = "#{object.type} #{object.path}"
  if object.type == :class && object.superclass.name != :Object
    definition << " < #{object.superclass.path}"
  end
  output = StringIO.new
  # output.puts generate_docstring(object)
  output.puts definition
  output.string
end

def generate_mixins(object, scope)
  output = StringIO.new
  mixin_type = (scope == :class) ? 'extend' : 'include'
  mixins = run_verifier(object.mixins(scope))
  mixins = stable_sort_by(mixins, &:path)
  mixins.each { |mixin|
    output.puts "  #{mixin_type} #{mixin.path}"
  }
  output.string
end

def list_all_classes
  # versions = Set.new
  klasses = []
  class_objects.each { |object|
    # version_tag = object.tag(:version)
    # versions << version_tag.text if version_tag
    klasses << namespace_definition(object)
  }
  # puts klasses.sort.join("\n")
  puts klasses.sort.join
  exit # Avoid the YARD summary
end
