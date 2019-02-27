def javascripts_full_list
  %w(js/jquery.js js/full_list.js js/sketchup.js)
end

# Custom search list grouping the classes in the API into similar groups.
# TODO(thomthom): This file is just a stub.

def generate_categories_list
  # @items = [
  #   "App Level Classes",
  #   "Entity Classes",
  #   "Collection Classes",
  #   "Geom Classes",
  #   "UI Classes",
  #   "Observer Classes",
  #   "Core Ruby Classes"
  # ]
  p 'generate_categories_list'
  p list_of_categories
  @items = list_of_categories.keys.sort
  @list_title = "Object Index"
  @list_type = "categories"

  # optional: the specified stylesheet class
  # when not specified it will default to the value of @list_type
  @list_class = "class"

  # Generate the full list html file with named feature_list.html
  # @note this file must be match the name of the type
  asset(url_for_list(@list_type), erb(:full_list))

  # generate_file_list
  # @file_list = true
  # @items = options.files
  # @list_title = "File List"
  # @list_type = "file"
  # generate_list_contents
  # @file_list = nil
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

private

def list_of_categories
  categories = {}
  Registry.all(:class, :module).each { |object|
    object.tags(:category).each { |tag|
      categories[tag.name] ||= []
      categories[tag.name] << object
    }
  }
  categories
end
