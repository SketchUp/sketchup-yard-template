# frozen_string_literal: true

def init
  super
  # Add an "api" section to docstrings. This will cause the `api` method
  # below to be called which will in turn render the `api` template.
  @sections.unshift(:api)
end

def api
  return unless object.has_tag?(:api)
  # Displays a a message warning the user that the API is not stable.
  erb(:api)
end
