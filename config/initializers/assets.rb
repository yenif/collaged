# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )

# Precompile Stimulus controllers
Rails.application.config.assets.precompile += %w(
  controllers/hello_controller.js
  controllers/collage_form_controller.js
  controllers/upload_controller.js
  controllers/photo_resize_controller.js
  controllers/grid_controller.js
  controllers/helpers/math_helpers.js
  controllers/application.js
  controllers/index.js
)
