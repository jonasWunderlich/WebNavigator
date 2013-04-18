v_max = 5;

filter = results:50, time:0, query:"", mode:"none"
history_array = []
bookmarks = []

processed = 0
historyWithRef = []
tabconnections = []

hSlider = 0

$(document).ready ->
      
  chrome.storage.local.get "query", (result) ->
    if result.query?
      filter.query = result.query
      $("#search").val result.query
      
  chrome.storage.local.get "hSlider", (result) ->
    if result.hSlider?
      query_slider.x = result.hSlider
      
  #slider to configure amount of Historydata
  min = 50; max = 500
  query_slider = new Dragdealer('simple-slider',
    x: hSlider, steps: max
    callback: (x, y) -> filter.results = parseInt (max-min)*query_slider.value.current[0]+min; $('#historycontent').empty(); chrome.storage.local.set "hSlider":x; loadHistory()
    animationCallback: (x, y) -> $("#handle_amount").text parseInt((max-min)*x+min)
  )
  $("#search").change ->
    filter.query = $('#search').val()
    $("#historycontent").empty()
    chrome.storage.local.set "query":filter.query
    loadHistory()
 
   
  chrome.storage.local.get "connections", (result) ->
    if result.connections? then tabconnections = result.connections
    else tabconnections = []
    loadBookmarks()
 
  null

# 1: Load all Bookmarks and save them in the history_array
loadBookmarks = () ->
  todo = 0
  chrome.bookmarks.getTree (bookmarkTreeNodes) ->
    morebms = bookmarkTreeNodes[0].children[1].children;
    for n in morebms
     if n.title is "conmarks"
      for m in n.children
        todo++
        if m.children?
          for o in m.children 
            todo++
            bookmarks.push context:m.title, id:o.title.split("___", 1)[0], bid:o.id
            #console.log todo
            todo--
          todo--
        else
          bookmarks.push context:undefined, id:m.title.split("___", 1)[0], bid:m.id
          todo--
          #console.log todo
    if todo is 0 and bookmarks.length isnt 0 then loadHistory()
    null



# 2: Load Historydata
loadHistory = () ->
  time = filter.time
  mode = filter.mode
  
  processed = 0;
  requeststodo = 0
  
  date = new Date()
  daydate = date.getTime()-((((date.getHours()+1) * 60 + date.getMinutes()) * 60 + date.getSeconds() ) * 1000)
  microsecondsPerDay = 1000 * 60 * 60 * 24
  endtime   = daydate - (microsecondsPerDay * (time-1))
  starttime = daydate - (microsecondsPerDay * (30+time))
  chrome.history.search({text:filter.query, maxResults:filter.results, startTime:starttime, endTime:endtime}
    (historyItems) ->
      #console.log historyItems
      historyItems.forEach (n) ->
        processed++;
        url = n.url
        title = n.title
        processVisitsWithUrl = (url,title) ->
          (visitItems) -> processVisits(url, title, visitItems, bookmarks)
        chrome.history.getVisits({url:n.url}, processVisitsWithUrl(url,title))
        requeststodo++
      null)
  if !requeststodo then return null #getBookmarks()
  null





processVisits = (url, title, visitItems, bookmarks) ->

  type = visitItems[visitItems.length-1].transition
  vid = visitItems[visitItems.length-1].visitId
  ref = visitItems[visitItems.length-1].referringVisitId
  relevance = visitItems.length
  url = url
  context = undefined
  bid = undefined
  special = undefined
  title = title

  if title is ""
    special = "empty"
    title = url
  else
    if ((url.substr -4) is ".jpg") or ((url.substr -4) is ".png") or ((url.substr -5) is ".jpeg")
      special = "image"
      title = "Abbildung"
    else if (/youtube/.test(url)) && (/watch/.test(url))
      special = "video"
    else if /Google-Suche/.test(title)
      special = "google"

  bookmark = (i for i in bookmarks when i.id is vid)[0]
  
  if bookmark? 
    context = bookmark.context
    bid = bookmark.bid
 
  item = id:vid, type:type, url:url, context:context, title:title, bid:bid, special:special, ref:ref, relevance:relevance
  
  historyWithRef.push(item)
  processed--;
  if processed is 0 then renderAlternative()
  #renderItem(item)
   


renderAlternative = () ->
  
  referrer = []
  referrer[666] = "chrome://newtab/"
  
  for tc in tabconnections
    id = 0; rid = tc.refurl
    for item in historyWithRef
      if item.url is tc.refurl then rid = item.id
      if item.url is tc.url then id = item.id
    referrer[id] = rid
              
  for item in historyWithRef
    if item.ref is "0" and referrer[item.id]
        item.ref = referrer[item.id]
        
  historyWithRef.reverse()
  while historyWithRef.length > 0
    renderItem(historyWithRef.pop())

   
   


renderItem = (item) ->
  url = item.url
  title = item.title
  context = item.context
  id = item.id
  type = item.type
  bid = item.bid
  special = item.special
  ref = item.ref
  relevance = item.relevance
  # falls refid auf url des vorgängerszeigt ->verlinken
  
  t_panel = $ "<div>"
  t_panel.addClass "panel"
  t_panel.addClass type
  if ref is "0" then t_panel.addClass "refzero"
  t_panel.addClass special  
  c_panel = $ "<div>"
  c_panel.addClass context
  c_panel.addClass bid
  
    
  if relevance>20  then t_panel.addClass "rel_big"
  else if relevance>5  then t_panel.addClass "rel_some"
  else if relevance>=2  then t_panel.addClass "rel_twice"
    
  link = $ "<a>"
  link.attr href:url
  link.addClass "urladress"
  inhalt = $ "<p>" 
  
  favicon = $ "<img>"
  favicon.attr src:"chrome://favicon/"+url
  favicon.addClass "favicon"
  c_panel.append $ favicon
  
  referer = $ "<p>"
  referer.addClass "referrer"
  referer.text id + " <- " + ref
  
  #console.log special
  if special isnt "google"
    button = $ "<button>"
    button.text "1"
    button.click () -> bookmark(c_panel, bid, id, url, title, "first")
    button2 = $ "<button>"
    button2.text "2"
    button2.click () -> bookmark(c_panel, bid, id, url, title, "second")
    button3 = $ "<button>"
    button3.text "3"
    button3.click () -> bookmark(c_panel, bid, id, url, title, "third")
    c_panel.append $ button
    c_panel.append $ button2
    c_panel.append $ button3
  
  clear = $ "<div>"
  clear.addClass "clear"
  c_panel.append $ clear
  
  if filter.query isnt ""
    qtl = filter.query.toLowerCase(); ttl = title.toLowerCase(); utl = url.toLowerCase()
    if ttl.indexOf(qtl) < 0 && utl.indexOf(qtl) > 0
      t_panel.addClass "lessimportant"
    else if ttl.indexOf(qtl) < 0 && utl.indexOf(qtl) < 0
      t_panel.addClass "unimportant"
            
 
  if special is "image" then pic = $ "<img>"; pic.attr src:url.substr(url.search /http/); pic.addClass "imgpreview"; inhalt.append pic; link.append $ inhalt
  else if url? and special is "video"
    if (v_max >= 0)
      vid = $ "<iframe>"; vid.addClass "youtubevideo"; #vid.attr width:"200"; vid.attr height:"80"; vid.attr frameborder:"0";
      y_id = "https://www.youtube.com/embed/" + url.split("watch?v=")[1].split('=')[0].split('&')[0]
      vid.attr src:y_id;  c_panel.append vid
      v_max--;
    else inhalt.text title; inhalt.attr id:id; link.append $ inhalt
  else if special is "google" then title = title.split(" - Google-Suche")[0]; inhalt.text title; inhalt.attr id:id; link.append $ inhalt
  else inhalt.text title; inhalt.attr id:id; link.append $ inhalt

  t_panel.addClass special
  
  c_panel.append $ link
  c_panel.append $ referer
  t_panel.append $ c_panel
  $("#historycontent").append $ t_panel

