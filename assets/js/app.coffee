$ = jQuery

class IndexReport extends Spine.Model
  @configure "IndexReport", "data"

  @url: "/model/" + model_name + "/check_index"
  
  @fetch: () ->
    $.getJSON @url, (d) =>
      report = IndexReport.create data: d
      report
    .error () ->
      # TODO
      #     Don't do it here.
      $("#index-report").html("something wrong")

class IndexReportView extends Spine.Controller

  constructor: ->
    super
    @template = jade.compile $("#index-report-tpl").text()

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
    report = IndexReport.fetch()
    report

  showIndexReport: (report) ->
    view = new IndexReportView report: report
    $("#index-report").html(view.render().el)

  constructor: ->
    super
    IndexReport.bind 'create', @showIndexReport

    
$ ->
  new MainApp(el: $('body'))

