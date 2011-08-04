class Collage extends Backbone.Model
  photos: =>
    return this.photos_collection ?= new PhotoCollection([],{
      url: this.url() + PhotoCollection.prototype.url
    })

  validate: (attrs) ->
    if !('title' of attrs && attrs.title.length > 0)
      return {title: "must not be blank"}

class window.CollageCollection extends Backbone.Collection
  model: Collage
  initialize: (models, options) ->
    this.url = options.url

window.Collage = new CollageCollection([],{url: '/collages'})
