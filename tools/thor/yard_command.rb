class YardCommand

  def initialize(base_command)
    @command = [base_command]
  end

  def <<(command_argument)
    @command << command_argument
  end

  def command_line
    @command.join(' ')
  end

  def exec
    puts command_line
    Kernel.exec command_line
  end

  def run
    puts command_line
    `#{command_line}`
  end

end
