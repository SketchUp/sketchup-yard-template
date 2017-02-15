require './tools/thor/yard_helper'

class Changelog < Thor

  include YardHelper

  desc "make", "Generates a changelog for the Ruby API"
  yard_method_options
  def make
    command = yard_command("yardoc -t changelog -f text")
    command.exec
  end
  default_task :make

end
