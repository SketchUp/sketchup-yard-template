require 'logger'
require 'json'

# gem install colorize
require 'colorize'
require 'yard'
require 'set'
require 'stringio'

# gem install git
# gem install git_diff_parser
require 'git'
require 'git_diff_parser'

require './tools/thor/yard_helper'

class Diff < Thor

  include YardHelper

  desc "list", "Diff Ruby API documentation changes"
  def list
    file_objects = find_changed_api_objects
    object_names = get_changed_objects_names(file_objects)
    puts object_names.join("\n").yellow
  end
  default_task :list

  desc "preview OBJECT", "See the changes for an incoming change"
  def preview(object_path)
    file_objects = find_changed_api_objects
    # Find the object we are looking for.
    object = nil
    change = nil
    file_objects.each { |file_object|
      change = file_object[:objects].find { |object| object[:object] == object_path }
      object = file_object
      break if change
    }
    # Read the docstring from the changed stub.
    doc_string_lines = get_change_docstring(change, object[:file])
    # Strip out the Ruby comment syntax in order to obtain a language neutral
    # docstring.
    stripped_lines = strip_ruby_comment(doc_string_lines)
    doc_string = stripped_lines.join("\n")
    # We can then generate a C++ docstring.
    cpp_doc_string = cpp_comment(stripped_lines)

    start_line = change[:start] + 1
    end_line = change[:end] + 1
    puts "File: #{object[:file]}".green
    puts "Lines: #{start_line}...#{end_line} (#{end_line - start_line} lines)".yellow
    puts
    separator = '=' * 80
    puts separator
    puts doc_string.cyan
    puts separator
  end

  desc "find OBJECT", "Find the origin of a given API object in our C++ source"
  def find(object_path)
    YARD::Registry.load!
    object = YARD::Registry.at(object_path)
    puts "File: #{object.file}".green
    puts "Lines: #{object.docstring.line_range} (#{object.docstring.line_range.size} lines)".yellow
    puts
    separator = '=' * 80
    puts separator
    puts object.docstring.all.cyan
    puts separator
  end

  desc "merge", "Merge incoming changes from the stubs to P4 source"
  def merge
    YARD::Registry.load!

    # Find what object changed in the stubs repository.
    file_objects = find_changed_api_objects

    # Get a list of names for all the changed API object.
    object_names = get_changed_objects_names(file_objects)
    puts object_names.join("\n").magenta

    # Find the changes API objects in the C++ source.
    source_objects = object_names.map { |object_name|
      object = YARD::Registry.at(object_name)
      raise 'Unable to find object' unless object
      object
    }
    puts "#{source_objects.size} objects affected"

    # Collect a list of CPP files that will be affected.
    source_files = source_objects.map { |object|
      find_object_source_file(object)
    }.uniq
    puts "#{source_files.size} files affected"

    # Check if they are writable. If they are not, they are probably not checked
    # out in Perforce. Offer to check out files to default changelist.
    locked_files = source_files.reject { |filename|
      File.writable?(filename)
    }
    if locked_files.empty?
      puts 'Some files are writable.'.red
      puts 'This could indicate the files have been modified.'
      puts 'Please commit or revert the following files:'
      puts source_files.join("\n").yellow
      # TODO(thomthom): Offer to revert files.
      exit
    else
      puts locked_files.join("\n").yellow
      exit if no?('Check out listed files to default changelist?')
      files = locked_files.join(' ')
      p system("p4 edit #{files}")
    end

    # TODO(thomthom): Open files and make text replacements.
    file_objects.each { |file_object|
      offset = 0
      file_object[:objects].each { |object|
        offset = replace_docstring(object, file_object[:file], offset)
        #puts "Offset: #{offset}".cyan
      }
    }
  end

  private

  DIFF_HEADER = /^diff --git a\/(.*)\s+b\//
  DIFF_HUNK = /^@@\s+\-(\d+),(\d+)\s+\+(\d+),(\d+)\s+@@\s?/

  RUBY_NAMESPACE = /^(?:class|module)\s(\S+)/
  RUBY_CLASS_METHOD = /^\s*def\s(?:self\.)(.+?)(?:[(]|$)/
  RUBY_INSTANCE_METHOD = /^\s*def\s(.+?)(?:[(]|$)/
  RUBY_COMMENT_LINE = /^\s*#/

  CPP_COMMENT_START = /^\s*\/\*/
  CPP_COMMENT_END = /\*\/\s*$/

  def find_object_source_file(object)
    # For virtual methods, like methods on the Tool class, YARD isn't
    # returning a file. For now we'll try to get that from the class/module
    # doc object.
    if object.file.nil?
      object_name = object.path
      puts object_name.magenta
      parent_name = object_name.split(/[#.]/).first
      puts "No source file found for #{object_name}.".magenta
      puts "Falling back to containing module/class #{parent_name}...".magenta
      parent = YARD::Registry.at(parent_name)
      File.expand_path(parent.file)
    else
      File.expand_path(object.file)
    end
  end

  def replace_docstring(change, filename, offset)
    puts
    puts "Object #{change[:object]}".green
    # Source docstring
    puts "Source File: #{filename}".yellow
    start_line = change[:start] + 1
    end_line = change[:end] + 1
    puts "> Lines: #{start_line}...#{end_line} (#{end_line - start_line} lines)"
    source_docstring = get_change_docstring(change, filename)
    #puts '=' * 20
    #puts source_docstring.join("\n").cyan
    #puts '-' * 20
    # Target docstring
    object_path = change[:object]
    cpp_object = YARD::Registry.at(object_path)
    cpp_file = find_object_source_file(cpp_object)
    puts "Target File: #{cpp_file}".yellow
    puts "> Lines: #{cpp_object.docstring.line_range} (#{cpp_object.docstring.line_range.size} lines)"
    # Strip out the Ruby comment syntax in order to obtain a language neutral
    # docstring.
    stripped_lines = strip_ruby_comment(source_docstring)
    # Need to inject special instructions for our classes/modules and some of
    # our methods.
    case cpp_object.type
    when :class, :module
      type = cpp_object.type.to_s
      stripped_lines.unshift("Document-#{type}: #{cpp_object.path}", "")
    when :method
      # Virtual methods, where we document a method without actually having
      # an implementation will need to have this explicit directive in order
      # for YARD to pick it up.
      if cpp_object.file.nil?
        stripped_lines.unshift("Document-method: #{cpp_object.path}", "")
      end
    end
    doc_string = stripped_lines.join("\n")
    # Restore @overload tags.
    doc_string = reformat_docstring(doc_string, cpp_object)
    #puts '=' * 20
    #puts doc_string.cyan
    #puts '-' * 20
    # We can then generate a C++ docstring.
    cpp_doc_string = cpp_comment(doc_string.lines)
    cpp_doc_string_lines = cpp_doc_string.lines
    cpp_doc_string_lines.each { |line| line.chomp! }
    #puts
    #puts cpp_doc_string.cyan
    #puts
    cpp_lines = File.read(cpp_file).lines
    cpp_lines.each { |line| line.chomp! }
    cpp_range = cpp_object.docstring.line_range
    # Expand the range to include the start and end of the C++ comment. YARD
    # Doesn't preserve this.
    cpp_begin = find_start_of_cpp_comment(cpp_lines, offset + cpp_range.begin)
    cpp_end   = find_end_of_cpp_comment(cpp_lines, offset + cpp_range.last)
    cpp_range = (cpp_begin .. cpp_end)
    puts "> Offset Lines: #{cpp_range} (#{cpp_range.size} lines)".yellow
    #puts '=' * 20
    #puts cpp_lines[cpp_range]
    #puts '-' * 20
    #puts cpp_doc_string_lines
    #puts '=' * 20
    # Replace the changed lines.
    cpp_lines[cpp_range] = cpp_doc_string_lines
    # Compile the new document.
    cpp_content = cpp_lines.join("\n")
    File.write(cpp_file, cpp_content)
    # Since the C++ file is changed we need to take into account that files
    # might have been added/removed when replacing multiple comments in a file.
    # The line difference is returned so it can be used in consecutive calls to
    # this method.
    #puts "C++ Old Lines: #{cpp_range.size}"
    #puts "C++ New Lines: #{cpp_doc_string_lines.size}"
    #puts "       Offset: #{offset}"
    offset + (cpp_doc_string_lines.size - cpp_range.size)
  end

  def reformat_docstring(doc_string, cpp_object)
    return doc_string unless cpp_object.is_a?(YARD::CodeObjects::MethodObject)
    # If the method have parameters we need to check if we need to add an
    # overload for the C++ doc comment.
    cpp_params = cpp_object.parameters.map { |param| param.first }
    return doc_string if cpp_params.empty?
    ds = YARD::DocstringParser.new.parse(doc_string).to_docstring
    # We only need to inject an overload if the doc comment doesn't already
    # have overloads.
    overloads = ds.tags(:overload)
    return doc_string unless overloads.empty?
    # If the C++ param list doesn't match the Ruby stub param list we need to
    # add an overload.
    param_tags = ds.tags(:param)
    param_names = param_tags.map { |tag| tag.name }
    return doc_string if param_names.sort == cpp_params.sort
    # Generating overload signature.
    params_signature = param_names.join(', ')
    signature = "#{cpp_object.name}"
    signature << "(#{params_signature})" unless cpp_params.empty?
    # Injecting @overload tag before the first @param tag.
    doc_string.sub!('@param', "@overload #{signature}\n@param")
    # Indent all @params tags.
    param_pattern = /(@param\s.+?)^\s*$/m
    results = doc_string.scan(param_pattern)
    results.each { |result|
      indented = StringIO.new
      result[0].lines { |line|
        indented.puts "  #{line.chomp}"
      }
      doc_string.sub!(result[0], indented.string)
    }
    # Now reformat the doc string using YARD to keep things consistent.
    ds = YARD::DocstringParser.new.parse(doc_string).to_docstring
    output = StringIO.new
    ds.to_raw.lines.each { |line|
      output.puts if line.start_with?('@') # Adds extra line between tags.
      output.puts line
    }
    output.string
  end

  def find_start_of_cpp_comment(lines, line_number)
    line_number.downto(0) { |line_number|
      line = lines[line_number]
      return line_number if line.match(CPP_COMMENT_START)
    }
    0
  end

  def find_end_of_cpp_comment(lines, line_number)
    line_number.upto(lines.size - 1) { |line_number|
      line = lines[line_number]
      return line_number if line.match(CPP_COMMENT_END)
    }
    lines.size - 1
  end

  def strip_ruby_comment(docstring_lines)
    docstring_lines.map { |line| line.gsub(/^\s*#\s?/, '').rstrip }
  end

  def cpp_comment(lines)
    comment = StringIO.new
    comment.puts "/**"
    lines.each { |line| comment.puts " * #{line}".rstrip }
    comment.puts " */"
    comment.string
  end

  def get_change_docstring(change, file)
    lines = File.read(file).lines
    start_index = change[:start]
    end_index = change[:end]
    doc_string_lines = lines[start_index..end_index]
    doc_string_lines.each { |line| line.chomp! }
    doc_string_lines
  end

  def get_changed_objects_names(file_objects)
    object_names = []
    file_objects.each { |file_object|
      file_object[:objects].each { |object|
        object_names << object[:object]
      }
    }
    object_names
  end

  def find_changed_api_objects
    # TODO(thomthom): Get path from config.
    source_path = 'C:/Users/tthomas2/SourceTree/ruby-api-stubs'

    git = Git.open(source_path)
    puts "Current branch: #{git.current_branch}".yellow

    if git.current_branch == 'master'
      puts "Current branch is master."
      puts "Please check out a dev branch with changes."
      exit
    end

    work_path = Dir.pwd
    begin
      Dir.chdir(source_path)
      common = `git merge-base master #{git.current_branch}`
      puts "Common commit: #{common}"
      data = git.lib.commit_data(common)
      puts data['author'].magenta
      puts data['message'].magenta
    ensure
      Dir.chdir(work_path)
    end

    # Diff only checked in changes.
    diffs = git.diff(common, git.current_branch)

    # Extract what lines changed from the git diffs.
    changes = diffs.map do |diff|
      parse_patch(diff.patch)
    end

    # Determine what API objects (methods, classes, modules) changed.
    objects = find_objects(changes, source_path)
    objects
  end

  def find_objects(changes, source_path)
    objects = []
    changes.each { |change|
      #puts "Change: #{change[:file]}".cyan
      next unless change[:file].end_with?('.rb')
      changed_lines = find_changed_lines(change, source_path)
      line_numbers = changed_lines.map { |change| change[:line] }
      changed_objects = find_changed_objects(change, line_numbers, source_path)
      objects << changed_objects
    }
    objects
  end

  def find_changed_objects(change, line_numbers, source_path)
    filename = File.join(source_path, change[:file])

    content = File.read(filename)
    begin
      namespace = content.match(RUBY_NAMESPACE).captures.first
    rescue NoMethodError
      puts filename.yellow
      puts content.magenta
      puts JSON.pretty_generate(change)
      raise
    end

    lines = content.lines
    # Found APi objects that have changed:
    objects = []
    # Line numbers parsed:
    parsed = Set.new
    # Line numbers to parse:
    stack = line_numbers.map { |line_number| line_index = line_number - 1 }.sort
    until stack.empty?
      # We pick a line number and use that as a base to scan the file.
      line_number = stack.shift
      next if parsed.include?(line_number)
      parsed << line_number
      # Given a line number where a change was made, scan the file until we
      # find a line that isn't a Ruby comment. That will be the end of the
      # docstring and we can determine what object it relates to.
      lines[line_number..-1].each_with_index { |line, offset|
        # We need to take into account the base line number in addition to how
        # far we currently have scanned.
        current_line_number = line_number + offset + 1
        parsed << current_line_number
        next if line =~ RUBY_COMMENT_LINE
        # Found a non-comment line - this means we can try to determine what
        # object the change belonged to.
        object_path = nil
        if result = line.match(RUBY_CLASS_METHOD)
          method_name = result.captures.first
          object_path = "#{namespace}.#{method_name}"
        elsif result = line.match(RUBY_INSTANCE_METHOD)
          method_name = result.captures.first
          object_path = "#{namespace}##{method_name}"
        elsif line.match(RUBY_NAMESPACE)
          object_path = namespace.dup
        elsif line.strip.empty?
          # Ignore white-space and keep scanning.
          next
        else
          puts 'Uh oh...'.white.on_red
          puts JSON.pretty_generate(change)
          puts "File name: #{filename}"
          puts "Line numbers: #{line_numbers}"
          puts "Line number: #{line_number}"
          puts "Current line number: #{current_line_number}"
          p line
          p objects
          raise 'Unable to determine what object changed'
        end
        # We then scan the file upwards to determine the start of the docstring.
        # This will give us the range of the changes along with the API object
        # that was changed.
        # TODO(thomthom): Refactor to custom class.
        objects << {
          start: find_start_line_number(lines, line_number),
          end: current_line_number - 2,
          base_line_number: line_number,
          line: current_line_number,
          content: line,
          object: object_path
        }
        break
      }
    end
    {
      file: filename,
      objects: objects
    }
  end

  def find_start_line_number(lines, line_number)
    line_number.downto(0) { |line_number|
      line = lines[line_number]
      return line_number + 1 if line.strip.empty?
    }
    0
  end

  def find_changed_lines(change, source_path)
    filename = File.join(source_path, change[:file])
    lines = File.read(filename).lines
    changed_lines = []
    change[:hunks].each { |hunk|
      hunk[:additions].each { |addition|
        line_number = addition[:line]
        line_index = line_number - 1
        changed_lines << {
          line: line_number,
          content: lines[line_index]
        }
      }
    }
    changed_lines
  end

  def to_int(string)
    string ? string.to_i : 0
  end

  def parse_hunk(line)
    result = line.match(DIFF_HUNK)
    return nil unless result
    a_start, a_size, b_start, b_size = result.captures
    # TODO(thomthom): Refactor to custom class.
    {
      from: {
        start: to_int(a_start),
        size: to_int(a_size)
      },
      to: {
        start: to_int(b_start),
        size: to_int(b_size)
      },
      additions: [],
      deletions: [],
    }
  end

  def line_info(git_line, line_start, line_offset)
    # TODO(thomthom): Refactor to custom class.
    x = {
      line: line_start + line_offset,
      content: git_line[1..-1],
      line_start: line_start,
      line_offset: line_offset,
    }
    x
  end

  def parse_patch(diff_string)
    # http://stackoverflow.com/questions/2529441/how-to-read-the-output-from-git-diff
    # http://stackoverflow.com/a/2530012
    lines = diff_string.lines
    file = lines[0].match(DIFF_HEADER)[1]
    hunks = []
    add_offset = 0
    remove_offset = 0
    lines.each_with_index { |line, index|
      line.chomp!
      if hunk = parse_hunk(line)
        add_offset = 0
        remove_offset = 0
        hunks << hunk
      elsif !hunks.empty?
        if line.start_with?('+')
          hunk = hunks.last
          hunk[:additions] << line_info(line, hunk[:to][:start], add_offset)
          add_offset += 1
        elsif line.start_with?('-')
          hunk = hunks.last
          hunk[:deletions] << line_info(line, hunk[:from][:start], remove_offset)
          remove_offset += 1
        else
          add_offset += 1
          remove_offset += 1
        end
      end
    }
    {
      file: file,
      hunks: hunks
    }
  end

end # Diff
