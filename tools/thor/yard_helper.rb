require './tools/thor/yard_command'

module YardHelper

  module ClassMethods

    # Use this before a Thor method (command) to add default YARD options.
    def yard_method_options
      method_option :exclude, :aliases => "-e",
          :type => :array,
          :desc => "Excludes documentation for listed versions (i.e.: SU8 SU2016)"
      method_option :include, :aliases => "-i",
          :type => :array,
          :desc => "Includes documentation only for listed versions (i.e.: SU8 SU2016)"
      method_option :use_cache, :aliases => "-c",
          :type => :boolean,
          :desc => "Use YARDs cache when generating the stubs"
    end

  end # module

  def self.included(base)
    base.extend(ClassMethods)
  end

  private

  # Use this within a Thor method (command) to create a YardCommand wrapper
  # that handles the common options and execution.
  def yard_command(base_command)
    if options[:include] && options[:exclude]
      raise ArgumentError, "Cannot use --include and --exclude at the same time"
    end
    command = YardCommand.new(base_command)
    command << "-c" if options[:use_cache]
    command << exclude_query if options[:exclude]
    command << include_query if options[:include]
    command
  end

  def exclude_query
    filter = %(!#{version_filter(options[:exclude])})
    %(--query '#{filter}')
  end

  def include_query
    filter = %(#{version_filter(options[:include])})
    %(--query '#{filter}')
  end

  def version_filter(option_versions)
    versions = expand_versions(option_versions)
    quoted_versions = versions.map { |version| %("#{version}") }.join(', ')
    filter = %(@version.text.start_with?(#{quoted_versions}))
  end

  VERSION_PATTERN = /^(?<app>\D+)(?<major>[0-9.]+)(?<minor>\w+)?/
  def expand_versions(versions)
    versions.map { |version_string|
      # Expand short versions to full versions as used in the documentation.
      # Examples:
      # SU8      => SketchUp 8
      # SU2017   => SketchUp 2017
      # SU2017M1 => SketchUp 2017 M1
      result = VERSION_PATTERN.match(version_string)
      app   = result[:app].gsub("SU", "SketchUp")
      major = result[:major]
      minor = result[:minor] || ""
      "#{app} #{major} #{minor}".strip
    }
  end

end
