require 'logger'
require 'json'

# gem install colorize
require 'colorize'
require 'yard'
require 'set'
require 'stringio'

# gem install git
# gem install git_diff_parser
# gem install git_diff
require 'git'
require 'git_diff_parser'
#require 'git_diff'

require './tools/thor/yard_helper'

class Diff < Thor

  include YardHelper

  desc "list", "Diff Ruby API documentation changes"
  def list
    objects = find_changed_api_objects
    object_names = []
    objects.each { |file_objects|
      file_objects[:objects].each { |object|
        object_names << object[:object]
      }
    }
    puts object_names.join("\n")
  end
  default_task :list

  desc "preview OBJECT", "See the changes for an incoming change"
  def preview(object_path)
    file_objects = find_changed_api_objects
    #puts 'CHANGED API OBJECTS'
    #puts JSON.pretty_generate(file_objects)
    object = nil
    change = nil
    file_objects.each { |file_object|
      change = file_object[:objects].find { |object| object[:object] == object_path }
      object = file_object
      break if change
    }
    #puts 'CHANGE'
    #p change
    #puts 'OBJECT'
    #puts JSON.pretty_generate(object)
    lines = File.read(object[:file]).lines
    start_index = change[:start]
    end_index = change[:end]
    doc_string_lines = lines[start_index..end_index]
    doc_string_lines.each { |line| line.chomp! }
    stripped_lines = strip_ruby_comment(doc_string_lines)
    doc_string = stripped_lines.join("\n")
    cpp_doc_string = cpp_comment(stripped_lines)

    puts "File: #{object[:file]}".green
    puts "Lines: #{start_index+1}...#{end_index+1} (#{end_index-start_index} lines)".yellow
    puts
    separator = '=' * 80
    puts separator
    puts doc_string.cyan
    puts separator
  end

  desc "find OBJECT", "Find the origin of a given API object"
  def find(object_path)
    YARD::Registry.load!
    object = YARD::Registry.at(object_path)
    puts "File: #{object.file}".green
    puts "Lines: #{object.docstring.line_range} (#{object.docstring.line_range.size} lines)".yellow
    puts
    #puts object.docstring.to_raw
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
    object_names = []
    file_objects.each { |file_object|
      file_object[:objects].each { |object|
        object_names << object[:object]
      }
    }

    # Find the changes API objects in the C++ source.
    source_objects = object_names.map { |object_name|
      object = YARD::Registry.at(object_name)
      raise 'Unable to find object' unless object
      object
    }
    puts "#{source_objects.size} objects affected"

    # Collect a list of CPP files that will be affected.
    source_files = source_objects.map { |object|
      File.expand_path(object.file)
    }.uniq
    puts "#{source_files.size} files affected"

    # Check if they are writable. If they are not, they are probably not checked
    # out in Perforce. Offer to check out files to default changelist.
    locked_files = source_files.reject { |filename|
      File.writable?(filename)
    }
    if locked_files.empty?
      puts source_files.join("\n").yellow
    else
      puts 'Some files are not writable.'.red
      puts locked_files.join("\n").yellow
      exit if no?('Check out listed files to default changelist?')
      files = locked_files.join(' ')
      p system("p4 edit #{files}")
    end

    # TODO(thomthom): Open files and make text replacements.
  end

  private

  DIFF_HEADER = /^diff --git a\/(.*)\s+b\//
  DIFF_HUNK = /^@@\s+\-(\d+),(\d+)\s+\+(\d+),(\d+)\s+@@\s?/

  def strip_ruby_comment(docstring_lines)
    docstring_lines.map { |line| line.gsub(/^\s*#\s?/, '') }
  end

  def cpp_comment(lines)
    comment = StringIO.new
    comment.puts "/*"
    lines.each { |line| comment.puts " * #{line}" }
    comment.puts " */"
    comment.string
  end

  def find_changed_api_objects
    source_path = 'C:/Users/tthomas2/SourceTree/ruby-api-stubs'

    #git = Git.open(working_dir, :log => Logger.new(STDOUT))
    git = Git.open(source_path)
    puts "Current branch: #{git.current_branch}".yellow

    if git.current_branch == 'master'
      puts "Current branch is master."
      puts "Please check out a dev branch with changes."
      exit
    end

    # Diff only checked in changes.
    #diffs = git.diff(git.current_branch, 'master')
    diffs = git.diff('master', git.current_branch)
    #puts "Number of changed files: #{diffs.size}"
    #p diffs
    #exit

    #puts "Number of files: #{diffs.size}"
    #puts JSON.pretty_generate(diffs.stats)
    #puts JSON.pretty_generate(diffs.name_status)

    changes = diffs.map do |diff|
      #puts '=' * 20
      #puts 'PATCH'
      #puts '=' * 20
      #puts diff.patch
      parse_patch(diff.patch)
    end
    #puts '-' * 20
    #puts 'CHANGES'
    #puts '-' * 20
    #puts JSON.pretty_generate(changes)

    objects = find_objects(changes, source_path)
    #puts '-' * 20
    #puts 'OBJECTS'
    #puts '-' * 20
    #puts JSON.pretty_generate(objects)
    objects
  end

  def find_objects(changes, source_path)
    objects = []
    changes.each { |change|
      changed_lines = find_changed_lines(change, source_path)
      line_numbers = changed_lines.map { |change| change[:line] }
      changed_objects = find_changed_objects(change, line_numbers, source_path)
      objects << changed_objects
    }
    objects
  end

  RUBY_NAMESPACE = /^(?:class|module)\s(\S+)/
  RUBY_CLASS_METHOD = /^\s*def\s(?:self\.)(.+?)(?:[(]|$)/
  RUBY_INSTANCE_METHOD = /^\s*def\s(.+?)(?:[(]|$)/
  RUBY_COMMENT_LINE = /^\s*#/
  def find_changed_objects(change, line_numbers, source_path)
    filename = File.join(source_path, change[:file])

    content = File.read(filename)
    begin
      namespace = content.match(RUBY_NAMESPACE).captures.first
    rescue NoMethodError
      puts content
      raise
    end

    lines = content.lines
    objects = []
    parsed = Set.new
    stack = line_numbers.map { |line_number| line_index = line_number - 1 }.sort
    until stack.empty?
      line_number = stack.shift
      next if parsed.include?(line_number)
      parsed << line_number
      lines[line_number..-1].each_with_index { |line, offset|
        current_line_number = line_number + offset + 1
        parsed << current_line_number
        next if line =~ RUBY_COMMENT_LINE
        # TODO(thomthom): At the moment detect only methods. Stubs doesn't
        # include doc comments for classes/modules.
        object_path = nil
        if result = line.match(RUBY_CLASS_METHOD)
          method_name = result.captures.first
          object_path = "#{namespace}.#{method_name}"
        elsif result = line.match(RUBY_INSTANCE_METHOD)
          method_name = result.captures.first
          object_path = "#{namespace}##{method_name}"
        elsif line.match(RUBY_NAMESPACE)
          object_path = namespace.dup
        else
          puts "Line number: #{line_number}"
          puts "Current line number: #{current_line_number}"
          p line
          puts JSON.pretty_generate(change)
          raise 'Unable to determine what object changed'
        end
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
    x = {
      line: line_start + line_offset,
      content: git_line[1..-1],
      line_start: line_start,
      line_offset: line_offset,
    }
    #puts JSON.pretty_generate(x)
    x
  end

  def parse_patch(diff_string)
    #puts '/' * 20
    #puts 'PARSE PATCH'
    #puts '/' * 20
    # http://stackoverflow.com/questions/2529441/how-to-read-the-output-from-git-diff
    # http://stackoverflow.com/a/2530012
    #puts '=' * 20
    #puts diff_string
    #puts '=' * 20
    lines = diff_string.lines
    file = lines[0].match(DIFF_HEADER)[1]
    hunks = []
    add_offset = 0
    remove_offset = 0
    lines.each_with_index { |line, index|
      line.chomp!
      #puts "#{line} (#{line.match(DIFF_HUNK).inspect})"
      if hunk = parse_hunk(line)
        #puts "NEW HUNK: #{line}"
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
      #hunk_line_offset += 1
    }
    {
      file: file,
      hunks: hunks
    }
  end

end # Diff
