v_max = 0                                         # Maximum of Videos to show
filter = results:50, time:0, query:"", mode:"none" # Default Filter-Settings
min = 30; max = 1000
googlevisible = true

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
    if context is "nocontext" and !storedContexts[context]?
      storedContexts[context] = active:true
    if storedContexts[context].active then storedContexts[context].active = false
    else storedContexts[context].active = true
    chrome.storage.local.set "storedContexts":storedContexts
    null

  $("#configbar").on "click", "#hidegoogle", ->
    $(".googleblock").toggle("fast")
    googlevisible = !googlevisible


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









createBlocks = () ->
  blocksToProcess = blocks.length
  blocks.reverse()

  for block in blocks
    blocksToProcess--
    if block? and !block.processed
      if block.context is ""
        nocontextGroup = $ "<div>"
        nocontextGroup.addClass "contextgroup"
        nocontextGroup.addClass "group"+block.id
        nocontextGroup.addClass "nocontext"
        if block.google then nocontextGroup.addClass "googleblock"
        $("#historycontent").append $ nocontextGroup
      else
        for cblock in blocks
          if cblock? and cblock.context is block.context
            contextGroup = $ "<div>"
            contextGroup.addClass "contextgroup"
            contextGroup.addClass "group"+cblock.id
            contextGroup.addClass block.context
            $("#historycontent").append $ contextGroup
            cblock.processed = true
            if !storedContexts[block.context].active then $(".group"+cblock.id).hide()

    if blocksToProcess is 1
      siteHistory.reverse()
      for key,item of siteHistory
        $contextgroup = $(".group"+item.block)
        specialise(item, $contextgroup)
        for fblock in blocks
          if fblock? and item.block is fblock.id and fblock.context isnt ""
            $(".group"+item.block+" .panel .head").css "background", storedContexts[fblock.context].color

  if !googlevisible then $(".googleblock").toggle("fast")
  if !storedContexts["nocontext"].active
    $("#historycontent .nocontext").hide()

  $(".head").hover ( ->
    sInfo = {}
    sInfo.url = $(this).attr "url"
    sInfo.vid = $(this).attr "vid"
    sInfo.title = $(this).attr "title"
    sInfo.time = $(this).attr "time"
    createButtons($(this), "", sInfo)
    addClearDiv($(this))
  ), ->
    $(this).find("button").remove()
    $(this).find(".clear").remove()




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
  $('.colorPicker-palette').remove()
  #$('.contextgroup').remove()
  v_max = 0
  tabArray = {}
  start()
  null