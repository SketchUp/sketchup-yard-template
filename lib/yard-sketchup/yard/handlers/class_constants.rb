module SketchUpYARD
  class ClassConstantHandler < YARD::Handlers::C::Base

    MATCH = %r{\bDEFINE_RUBY_CLASS_CONSTANT\s*\(([^,]+)\s*,\s*([^,]+)\s*,\s*(\w+)\s*\)\s*;}xm
    handles MATCH
    statement_class BodyStatement

    process do
      statement.source.scan(MATCH) do |klass_name, value, const_name|
        type = "const"
        value = "nil"
        handle_constants(type, klass_name, const_name, value)
      end
    end

  end
end
