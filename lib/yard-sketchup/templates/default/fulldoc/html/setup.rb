def javascripts_full_list
  %w(js/jquery.js js/full_list.js js/sketchup.js)
end

# Custom search list grouping the classes in the API into similar groups.

def generate_categories_list
  @items = list_of_categories.sort { |a, b| a[0] <=> b[0] }
  @list_title = "Object Reference"
  @list_type = "categories"

  # Optional: the specified stylesheet class
  # when not specified it will default to the value of @list_type
  @list_class = "class"

  # Generate the full list html file with named feature_list.html
  generate_list_contents
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
