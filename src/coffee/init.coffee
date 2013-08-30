v_max = 0                                           # Maximum of Videos to show
filter = results:40, time:0, query:"", mode:"none" # Default Filter-Settings

bmarks = 0
phistory  = 0

$(document).ready ->

  # get Query from Storage
  chrome.storage.local.get "query", (result) ->
    if result.query?
      filter.query = result.query
      $("#search").val result.query

  #slider to configure amount of Historydata
  chrome.storage.local.get "hSlider", (result) ->
    if result.hSlider? then initSlider(result.hSlider)
    else initSlider(0)

  $("#search").change ->
    filter.query = $('#search').val()
    $("#historycontent").empty()
    chrome.storage.local.set "query":filter.query
    reload()

  bmarks = new hv.Bookmarks()
  phistory = new hv.ProcessHistory(filter)

  bmarks.loadBookmarks()

  try
    phistory.loadHistory()
  finally
    console.log  phistory.getHistory()


  #(phistory.loadHistory()) -> console.log phistory.getHistory()

  null





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






initSlider = (hSlider) ->
  min = 50; max = 500
  query_slider = new Dragdealer 'simple-slider',
    x: hSlider, steps: max
    callback: (x) -> filter.results = parseInt (max-min)*query_slider.value.current[0]+min;  chrome.storage.local.set "hSlider":x; reload()
    animationCallback: (x) -> $("#handle_amount").text parseInt((max-min)*x+min)








