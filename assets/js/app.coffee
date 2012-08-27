$ = jQuery

class Report extends Spine.Model
  @configure "Report", "data"

  @url: basepath + "/model/" + model_name
  
  @check: ->
    $.getJSON @url + '/check', (data) =>
      report = @create data: data
      report
    .error =>
      report = @create
        data:
          error: 'something wrong'
      
  @truncate: ->
    $.getJSON @url + '/truncate', (data) =>
      report = @create data: data
      report
    .error =>
      report = @create
        data:
          error: 'something wrong'


class Reports extends Spine.Controller

  constructor: ->
    super
    @template = jade.compile $("#report-tpl").text()

  render: =>
    @replace(@template report: @report)
    @

class PersistentView extends Spine.Controller

  render: =>
    @replace(@template)
    @

  constructor: ->
    super
    @template = jade.compile $("#persistent-tpl").text()

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
    "click #check-index-btn": "checkIndex"
    "click #truncate-btn": "truncate"

  elements:
    "#command-btn": "commandBtn"
    "#main": "main"

  showCommandPage: (e) ->
    e.preventDefault()
    view = new CommandView()
    $("#main").html(view.render().el.html())

  showPersistentPage: (e) ->
    e.preventDefault()
    view = new PersistentView()
    $("#main").html(view.render().el.html())

  checkIndex: (e) ->
    e.preventDefault()
    Report.check()

  truncate: (e) ->
    e.preventDefault()
    Report.truncate()

  showReport: (report) ->
    view = new Reports report: report
    $("#report").html(view.render().el)

  constructor: ->
    super
    Report.bind 'create', @showReport
    
$ ->
  new MainApp(el: $('body'))

