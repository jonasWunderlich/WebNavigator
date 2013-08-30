v_max = 0                                           # Maximum of Videos to show
filter = results:40, time:0, query:"", mode:"none" # Default Filter-Settings

bmarks = 0
phistory  = 0
tabArray = {}

$(document).ready ->

  chrome.storage.local.get "query", (result) ->
    if result.query?
      filter.query = result.query
      $("#search").val result.query

  chrome.storage.local.get "hSlider", (result) ->
    if result.hSlider? then initSlider(result.hSlider)
    else initSlider(0)

  $("#search").change ->
    filter.query = $('#search').val()
    $("#historycontent").empty()
    chrome.storage.local.set "query":filter.query
    reload()



  createBlocks = ()->
    console.log siteHistory

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
      if item.context != "" and !$(".group"+item.block).hasClass(item.context)
        $(".group"+item.block).addClass item.context
        $(".group"+item.block).removeClass "nocontext"
      if blockdings > item.block
        blockdings--
      specialise(item, $(".group"+item.block))
      if item.context isnt ""
        $(".group"+item.block+" .panel .head").css "background", storedContexts[item.context].color



  createHistory = () ->
    chrome.tabs.query {}, (tabs) ->
      for i in tabs
        tabArray[i.url] = i.id
    loadHistory(createBlocks)


  loadBookmarks(createHistory)


  $("#bookmarklist").on "click", "h2", ->
    context = $(this).context.className.split(" ")[0]
    console.log context
    toggleActiveState(context)
    if context isnt "nocontext"
      if storedContexts[context].active then storedContexts[context].active = false
      else storedContexts[context].active = true
      chrome.storage.local.set "storedContexts":storedContexts
    null

  null














initSlider = (hSlider) ->
  min = 50; max = 500
  query_slider = new Dragdealer 'simple-slider',
    x: hSlider, steps: max
    callback: (x) -> filter.results = parseInt (max-min)*query_slider.value.current[0]+min;  chrome.storage.local.set "hSlider":x; reload()
    animationCallback: (x) -> $("#handle_amount").text parseInt((max-min)*x+min)

reload = () ->
  chrome.storage.local.set "storedBookmarks":storedBookmarks
  $('#historycontent').empty()
  $('#bookmarklist').empty()
  v_max = 0
  siteHistory = []
  bookMarks = {}
  #tabconnections = {}
  blockId = 0
  blocks = {}
  visitId_pointo_SiteId = []
  #visitIdArray = []
  blockStyle = []
#loadBookmarks()