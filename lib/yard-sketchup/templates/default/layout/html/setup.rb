# Consider if this should simply replace the Classes list.

=begin
TODO(thomthom): Temporarily disabled until we have time to fully implement this.
def menu_lists
  # Load the existing menus
  super + [ { :type => 'object_types', :title => 'Object Reference', :search_title => 'Object Reference List' } ]
end
=end

def javascripts
  # Using the latest 1.x jQuery from CDN broke the YARD js. For now we must
  # continue to use the version shipping with the YARD template we use as base.
  #
  # UPDATE: jQuery 1.9 removed a number of functions.
  #   GitHub report security warnings for jQuery older than 1.9. In order to
  #   upgrade we vendor jQuery of a newer version (1.x branch) along with their
  #   migration plugin to allow YARD to continue to work.
  #   https://github.com/lsegal/yard/pull/1351
  %w(js/jquery.js js/jquery-migrate.js js/app.js)
end

def stylesheets
  %w(css/style.css css/sketchup.css css/rubyapi.css)
end
