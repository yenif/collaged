# http://quickleft.com/blog/rails-31-javascript-templating-with-sprockets
module Templater
  extend self

  def render_template(template, opts = {})
    Tilt.new(build_file(template, opts)).render.inspect.split("\\n").join
  end

  private
  def build_file(file, opts)
    relative_path = opts[:path] || "/app/views/templates"
    extension = opts[:extension] || ".html.erb"
    File.join Rails.root, "#{relative_path}/#{file.to_s}#{extension}"
  end
end
