class Photo extends Backbone.Model

class window.PhotoCollection extends Backbone.Collection
  url: '/photos'
  model: Photo
  initialize: (models = [], options = {}) ->
    this.url = options.url if 'url' of options
