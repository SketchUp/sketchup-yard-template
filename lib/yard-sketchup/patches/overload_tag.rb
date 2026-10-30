# frozen_string_literal: true
module SketchUpYARD
  # YARD measures the indent of an @overload body with /\A(\s*)/, which also
  # matches newlines. A blank line after the signature is then counted as
  # indent, and one space is lost from nested text such as @example code.
  # Removing the blank lines after the signature avoids this.
  module OverloadTagPatch
    private

    def parse_tag(text)
      super(text.sub(/\A(.*\n)(?:[ \t]*\n)+/, '\1'))
    end
  end
end

YARD::Tags::OverloadTag.prepend(SketchUpYARD::OverloadTagPatch)
