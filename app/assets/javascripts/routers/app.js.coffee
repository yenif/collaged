class window.AppRouter extends Backbone.Router
  routes:
    '/collages/:guid': 'collage_show'
    'collages/:guid':  'collage_show'
    '':                'collage_new'

  collage_new: ->
    (window.view = new CollageNew({el: $('div#content')})).render()

  collage_show: (guid) ->
    (window.view = new CollageShow({model: Collage.get(guid), el: $('div#content')})).render()
