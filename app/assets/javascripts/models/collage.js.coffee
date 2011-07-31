class window.Collage extends Backbone.Model
  urlRoot: "collages"
  validate: (attrs) ->
    if !(attrs.title.lenght > 0)
      return {title: "must not be blank"}
