require './tools/thor/yard_helper'

class Doc < Thor

  include YardHelper

  desc "make", "Build Ruby API documentation"
  yard_method_options
  def make
    command = yard_command("yardoc")
    command.exec
  end
  default_task :make

  desc "undocumented", "List undocumented Ruby API features"
  yard_method_options
  def undocumented
    command = yard_command("yard stats --list-undoc")
    command.exec
  end

  desc "versions", "Lists all known SketchUp versions in the Ruby API "
  yard_method_options
  def versions
    command = yard_command("yardoc -t versions -f text")
    command.exec
  end

end
