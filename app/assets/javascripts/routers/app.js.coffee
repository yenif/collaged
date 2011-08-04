class window.AppRouter extends Backbone.Router
  routes:
    '/collages/:guid': 'collage_show'
    'collages/:guid':  'collage_show'
    '':                'collage_new'

  collage_new: ->
    (new CollageNew({el: $('div#content')})).render()

  collage_show: (guid) ->
    (new CollageShow({model: Collage.get(guid), el: $('div#content')})).render()
