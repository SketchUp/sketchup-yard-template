module SketchUpYARD
  class GlobalConstantHandler < YARD::Handlers::C::Base

    MATCH = %r{\bDEFINE_RUBY_(?:(?:NAMED_)?CONSTANT|ENUM)\s*\((?:[^)]+,\s*)?(\w+)\)\s*;}xm
    handles MATCH
    statement_class BodyStatement

    process do
      statement.source.scan(MATCH) do |captures|
        const_name = captures.first
        type = "global_const"
        var_name = nil
        value = "nil"
        handle_constants(type, var_name, const_name, value)
      end
    end

  end
end
