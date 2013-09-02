v_max = 10                                           # Maximum of Videos to show
filter = results:50, time:0, query:"", mode:"none" # Default Filter-Settings
min = 30; max = 500
bmarks = 0
phistory  = 0
tabArray = {}

$(document).ready ->

  chrome.storage.local.get "query", (result) ->
    if result.query?
      filter.query = result.query
      $("#search").val result.query

  $("#search").change ->
    filter.query = $('#search').val()
    $("#historycontent").empty()
    chrome.storage.local.set "query":filter.query
    reload()

  $("#bookmarklist").on "click", "h2", ->
    context = $(this).context.className.split(" ")[0]
    toggleActiveState(context)
    if context isnt "nocontext"
      if storedContexts[context].active then storedContexts[context].active = false
      else storedContexts[context].active = true
      chrome.storage.local.set "storedContexts":storedContexts
    null

  chrome.storage.local.get "hSlider", (result) ->
    if result.hSlider?
      #null
      #filter.results = parseInt (max-min)*result.hSlider+min
      initSlider(0) #result.hSlider)
      #reload()
    else
      initSlider(0)

  start()
  null









createBlocks = ()->
  num = blockSum+1
  while num -= 1
    contextGroup = $ "<div>"
    contextGroup.addClass "contextgroup"
    contextGroup.addClass "nocontext"
    contextGroup.addClass "group"+num
    $("#historycontent").append $ contextGroup

  blockdings = blockSum+1
  siteHistory.sort (a,b) -> return if a.vid <= b.vid then 1 else -1

  for key,item of siteHistory
    #console.log item
    $contextgroup = $(".group"+item.block)
    if item.context != "" and !$contextgroup.hasClass(item.context)
      $contextgroup.addClass item.context
      $contextgroup.removeClass "nocontext"
      if !storedContexts[item.context].active then $contextgroup.hide()

    if blockdings > item.block
      blockdings--

    specialise(item, $contextgroup)
    if item.context isnt ""
      $(".group"+item.block+" .panel .head").css "background", storedContexts[item.context].color


createHistory = () ->
  chrome.tabs.query {}, (tabs) ->
    for i in tabs
      tabArray[i.url] = i.id
  loadHistory(createBlocks)


start = () ->
  loadBookmarks(createHistory)















initSlider = (hSlider) ->

  query_slider = new Dragdealer 'simple-slider',
    x: hSlider, steps: max
    callback: (x) -> filter.results = parseInt (max-min)*query_slider.value.current[0]+min;  chrome.storage.local.set "hSlider":x; reload()
    animationCallback: (x) -> $("#handle_amount").text parseInt((max-min)*x+min)

reload = () ->
  $('#historycontent').empty()
  $('#bookmarklist').empty()
  v_max = 5
  start()
  null