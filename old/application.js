// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require lib/underscore.js
//= require lib/backbone.js
//= require lib/plupload/plupload.js
//= require_tree ./lib
//= require_tree ./lib/plupload
//= require_tree ./models
//= require_tree ./views
//= require_tree ./routers
//= require_tree
//= require_self

// Make _.template like mustache so we don't conflict with erb
// should actually use mustache later
_.templateSettings = {
    interpolate : /\{\{(.+?)\}\}/g
};

// Fire everything up on page load
$(function(){
  window.app = new AppRouter
  Backbone.history.start({pushState: true})
});
