# puts "Loading SketchUp API YARD Plugin..."
# puts caller


module SketchUpYardPlugin

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


  class ClassEnumConstantHandler < YARD::Handlers::C::Base
    MATCH = %r{\bDEFINE_RUBY_CLASS_ENUM\s*\(([^,]+)\s*,\s*(\w+)\s*\)\s*;}xm
    handles MATCH
    statement_class BodyStatement

    process do
      statement.source.scan(MATCH) do |klass_name, const_name|
        type = "const"
        value = "nil"
        handle_constants(type, klass_name, const_name, value)
      end
    end
  end

end unless defined?(SketchUpYardPlugin)


# Hack to show some progress on Windows while building the docs.
# Helpful in seeing what takes most time.
# It's Copy+Paste from YARD 0.9.9 with some noted edits.
module YARD
  class Logger < ::Logger

    def show_progress
      return false if YARD.ruby18? # threading is too ineffective for progress support
      # <hack>
      # return false if YARD.windows? # windows has poor ANSI support
      # </hack>
      return false unless io.tty? # no TTY support on IO
      return false unless level > INFO # no progress in verbose/debug modes
      @show_progress
    end

    def progress(msg, nontty_log = :debug)
      send(nontty_log, msg) if nontty_log
      return unless show_progress
      icon = ""
      if defined?(::Encoding)
        icon = PROGRESS_INDICATORS[@progress_indicator] + " "
      end
      @mutex.synchronize do
        print("\e[2K\e[?25l\e[1m#{icon}#{msg}\e[0m\r")
        @progress_msg = msg
        @progress_indicator += 1
        @progress_indicator %= PROGRESS_INDICATORS.size
      end
      Thread.new do
        sleep(0.05)
        # <hack>
        # progress(msg + ".", nil) if @progress_msg == msg
        # </hack>
        progress(msg, nil) if @progress_msg == msg
      end
    end

  end
end if true # Set to false to disable hack.
