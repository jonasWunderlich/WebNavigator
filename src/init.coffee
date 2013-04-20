# Maximum of Videos to show
v_max = 5
# Default Settings of filtering the View
filter = results:50, time:0, query:"", mode:"none"
context = "empty"
hSlider = 0
processed = 0

# Temporaily Save all Bookmarks
bookMarks = {}
# Working Array
siteHistory = []
# Missing Tabconnections
tabconnections = []

siteNetwork = []
siteContext = []
vidArray = []
refArray = []


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
    callback: (x, y) -> filter.results = parseInt (max-min)*query_slider.value.current[0]+min;  chrome.storage.local.set "hSlider":x; reload()
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

reload = () ->
  $('#historycontent').empty()
  siteHistory = []
  bookMarks = {}
  loadBookmarks()
  vidArray = []
  siteContext = []
  

# 1: Load all Bookmarks and save them in bookmarks[]
loadBookmarks = () ->
  todo = 0
  chrome.bookmarks.getTree (bookmarkTreeNodes) ->
    #console.log bookmarkTreeNodes
    morebms = bookmarkTreeNodes[0].children[1].children;
    for n in morebms
     if n.title is "conmarks"
      for m in n.children
        todo++
        if m.children?
          for o in m.children 
            todo++
            bookMarks[o.url] = context:m.title, id:o.title.split("___", 1)[0], bid:o.id
            todo--
          todo--
        else
          bookMarks[m.url] = context:undefined, id:m.title.split("___", 1)[0], bid:m.id
          todo--
    if todo is 0
      loadHistory()
    null


# 2: Load GoogleChrome-Historydata
loadHistory = () ->
  time = filter.time
  mode = filter.mode 
  processed = 0
  date = new Date()
  daydate = date.getTime()-((((date.getHours()+1) * 60 + date.getMinutes()) * 60 + date.getSeconds() ) * 1000)
  microsecondsPerDay = 1000 * 60 * 60 * 24
  endtime   = daydate - (microsecondsPerDay * (time-1))
  starttime = daydate - (microsecondsPerDay * (30+time))
  chrome.history.search({text:filter.query, maxResults:filter.results, startTime:starttime, endTime:endtime}
    (historyItems) ->
      historyItems.forEach (site) ->
        processed++
        chrome.history.getVisits {url:site.url}, (visitItems) -> processVisitItems(site, visitItems)
      null)
  null


  
  
processVisitItems = (site, visitItems) ->
  
  id = site.id
  vid = visitItems[visitItems.length-1].visitId
  type = visitItems[visitItems.length-1].transition
  ref = visitItems[visitItems.length-1].referringVisitId
  relevance = visitItems.length
  
  #console.log vid
  ###----------------------------------------------------------------------------------------###
  #console.log visitItems
  visits = []
  referrer = []
  for i in visitItems
    #console.log i.visitId
    visits.push i.visitId
    referrer.push i.referringVisitId
    vidArray[i.visitId] = sid:site.id
    refArray[i.referringVisitId] = i.visitId   ## nur eine Verbindung vorerst##
  siteNetwork[id] = visits:visits, referrer:referrer
  ###----------------------------------------------------------------------------------------###
  
  

  SiteItem = sid:site.id, vid:vid, url:site.url, title:site.title, type:type, ref:ref, relevance:relevance

  siteHistory[id] = SiteItem
  
  processed--;
  if processed is 0 then processTabConnections()
     


processTabConnections = () ->
  
  referrer = []
  referrer[666] = "chrome://newtab/"
    
  for tc in tabconnections.reverse()
    id = 0; rid = tc.refurl
    for key,item of siteHistory
      if item.url is tc.refurl then rid = item.vid; #console.log siteNetwork[key]
      if item.url is tc.url then id = item.vid
    referrer[id] = rid
              
  for key,item of siteHistory
    if item.ref is "0" and referrer[item.vid]
        item.ref = referrer[item.vid]
  
  bookmartise()
  



   

bookmartise = () ->
  
  bprocessed = 0;
  #console.log siteHistory
  for key,val of siteHistory
    bprocessed++
    #console.log "sid"
    #console.log val.vid
    #bookmark = (bmark for bmark in bookmarks when bmark.id is val.vid)[0]
    
    if bookMarks[val.url]
    #if bookmark? 
      #console.log bookMarks[val.url]
      val.context = bookMarks[val.url].context
      #val.bid = bookmark.bid
      #setConmark val.context, val.sid
      #for i in siteNetwork[val.sid].referrer
        #if i isnt "0" && vidArray[i]
          #console.log i
          #console.log siteNetwork[vidArray[i].sid].referrer
          #vidArray[i].context = bookmark.context+"next"

  if bprocessed = filter.results  
    siteHistory.sort (a,b) ->
      return if a.vid >= b.vid then 1 else -1
  
    console.log siteNetwork
    console.log vidArray
    console.log refArray
  
    for key,item of siteHistory.reverse()
      specialise(item)









setConmark = (context, sid) ->
  console.log context + " " + sid
  for i in siteNetwork[sid].referrer
    console.log vidArray[i]
    if i isnt "0" && vidArray[i]
      #console.log vidArray[i].sid
      #console.log i
      #console.log siteNetwork[vidArray[i].sid].referrer
      siteContext[i] = context+"next"
      setConmark context, vidArray[i].sid








specialise = (site) ->

  url = site.url
  title = site.title
  context = undefined
  special = undefined

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

  site.title = title
  site.special = special
  renderItem(site)









renderItem = (item) ->
  
  ## ############################################################################################
  #if item.context isnt undefined
  
  #console.log item.context
  #console.log item.id
  #console.log item.children
  ## ############################################################################################

  
  #console.log item.sid
  #console.log item.context
  

  
  
  url = item.url
  title = item.title
  sid = item.sid
  vid = item.vid
  type = item.type
  bid = item.bid
  special = item.special
  ref = item.ref
  relevance = item.relevance
  context = item.context
  
  #console.log item.context
  
  #console.log vidArray[i].context
  

  if context is undefined
    if siteContext[item.vid]?
      context = siteContext[item.vid]


    
  # falls refid auf url des vorgängerszeigt ->verlinken
  
  t_panel = $ "<div>"
  t_panel.addClass "panel"
  t_panel.addClass type
  if ref is "0" then t_panel.addClass "refzero"
  t_panel.addClass special  
  c_panel = $ "<div>"
  if context isnt undefined
    c_panel.addClass context
    c_panel.addClass vid
  
    
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

  referer.text vid + " <- " + ref
  
  #console.log special
  if special isnt "google" and special isnt "empty"
    button = $ "<button>"
    button.text "1"
    button.click () -> bookmarkIt(item, "first")
    button2 = $ "<button>"
    button2.text "2"
    button2.click () -> bookmarkIt(item, "second")
    button3 = $ "<button>"
    button3.text "3"
    button3.click () -> bookmarkIt(item, "third")#(c_panel, vid, url, title, "third")
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
      videoframe = $ "<iframe>"; videoframe.addClass "youtubevideo"; #vid.attr width:"200"; vid.attr height:"80"; vid.attr frameborder:"0";
      y_id = "https://www.youtube.com/embed/" + url.split("watch?v=")[1].split('=')[0].split('&')[0]
      videoframe.attr src:y_id;  c_panel.append videoframe
      v_max--;
    else inhalt.text title; inhalt.attr id:sid; link.append $ inhalt
  else if special is "google" then title = title.split(" - Google-Suche")[0]; inhalt.text title; inhalt.attr id:sid; link.append $ inhalt
  else inhalt.text title; inhalt.attr id:sid; link.append $ inhalt

  t_panel.addClass special
  
  c_panel.append $ link
  c_panel.append $ referer
  t_panel.append $ c_panel
  $("#historycontent").append $ t_panel


    
    
    
    
    
    
    
    
bookmarkIt = (site, context) ->
  url = site.url
  context = context
  if bookMarks[url]?
    if bookMarks[url].context is context
      chrome.bookmarks.remove bookMarks[url].bid, ->
        reload()
    else if bookMarks[url].context isnt undefined
      chrome.bookmarks.remove bookMarks[url].bid, ->
        createBookmark site, context 
  else
    createBookmark site, context

  
createBookmark = (site, context) ->
  chrome.bookmarks.getTree (bookmarkTreeNodes) ->
    folder = bookmarkTreeNodes[0].children[1].children;
    newtitle = "#{site.vid}___#{site.title}"
    for sub in folder
      if sub.title is "conmarks"
        if context is undefined 
          chrome.bookmarks.create {parentId:file.id, title:newtitle, url:site.url}, ->
            reload()
        else
          for m in sub.children
            if context is m.title
              chrome.bookmarks.create {parentId:m.id, title:newtitle, url:site.url}, ->
                reload()