# Helpers:

# Copy verbatim an asset file to the target output. By default it uses the
# same relative path as the source for the target path.
def copy(source, target = nil)
  path = self.class.find_file(source)
  # puts "copy(#{source}, #{target})"
  # puts "> path: #{path}"
  raise ArgumentError, "no file for '#{source}' in #{self.class.path}" unless path
  target ||= source
  asset(target, File.binread(path))
end

# Template overrides:

def javascripts_full_list
  %w(js/jquery.js js/full_list.js js/sketchup.js)
end

def generate_assets
  super
  copy('favicon.ico')
  copy('images/SU_Developer-RedWhite.png')
  copy('images/trimble-logo-white.png')
end

# Custom search list grouping the classes in the API into similar groups.
# TODO(thomthom): This file is just a stub.

def generate_object_types_list
   #@items = options.objects if options.objects
   @items = [
      "App Level Classes",
      "Entity Classes",
      "Collection Classes",
      "Geom Classes",
      "UI Classes",
      "Observer Classes",
      "Core Ruby Classes"
   ]
   @list_title = "Object Index"
   @list_type = "object_types"

   # optional: the specified stylesheet class
   # when not specified it will default to the value of @list_type
   @list_class = "class"

   # Generate the full list html file with named feature_list.html
   # @note this file must be match the name of the type
   asset(url_for_list(@list_type), erb(:full_list))
end


# See `class_list` in fulldoc/html.
def reference_list
   even_odd = "odd"
   out = ""
   @items.each { |item|
      out << "<li class='#{even_odd}'>"
      out << "<a class='toggle'></a>"
      out << item
      out << "</li>"
      even_odd = (even_odd == 'even' ? 'odd' : 'even')
   }
   out
end
