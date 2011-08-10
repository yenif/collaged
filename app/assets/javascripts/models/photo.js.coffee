class Photo extends Backbone.Model
  size: (s) =>
    if s?
      this.set({size: s})
      @set_default_dimensions()

    return this.get('size') ? 1

  height: (h) =>
    if h?
      this.set({height: h})

    return this.get('height') ? 1

  width: (w) =>
    if w?
      this.set({width: w})

    return this.get('width') ? 1

  custom_aspect: (b) =>
    if b?
      this.set({custom_aspect: b})

    return this.get('custom_aspect') ? false

  image_height: =>
    return this.get('image_height') ? 0

  image_width: =>
    return this.get('image_width') ? 0

  set_default_dimensions: =>
    unless @width() * @height() == @size()
      factors = Math.factors(@size())

      if @custom_aspect()
        aspect = @height() / @width()
      else
        aspect = @image_height() / @image_width()

      high = factors.length - 1
      nearest_index = low = 0

      until high < low
        index = Math.floor((low + high) / 2)
        distance = (factors[index] / (@size() / factors[index])) - aspect

        if (!nearest_distance?) || nearest_distance > Math.abs(distance)
          nearest_index = index
          nearest_distance = Math.abs(distance)

        if distance < 0
          low = index + 1
        else if distance > 0
          high = index - 1
        else
          break

      @height(factors[nearest_index])
      @width(@size() / factors[nearest_index])

    return this

class window.PhotoCollection extends Backbone.Collection
  url: '/photos'
  model: Photo
  initialize: (models = [], options = {}) ->
    this.url = options.url if 'url' of options
