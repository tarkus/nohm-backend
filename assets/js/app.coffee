$ = jQuery

class CommandView extends Spine.Controller

  render: =>
    @replace(@template)
    @

  constructor: ->
    super
    @template = jade.compile $("#command-tpl").text()

class MainApp extends Spine.Controller
  events:
    "click #command-btn": "showCommandPage"
    "click #persistent-btn": "showPersistentPage"

  elements:
    "#command-btn": "commandBtn"
    "#main": "main"

  showCommandPage: (e) ->
    e.preventDefault()
    view = new CommandView()
    $("#main").html(view.render().el.html())

$ ->
  new MainApp(el: $('body'))

