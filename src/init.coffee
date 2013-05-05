# Maximum of Videos to show
v_max = 0
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
tabconnections = {}

siteContext = []
visitIdArray = {}
refArray = []



blockId = 0
blocks = {}
refToBlock = []
blockStyle = []

refMissing = []
urltoSid = {}
findOutlater = []
shortUrls = []









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
    reload()
 
  chrome.storage.local.get "tabConnections", (result) ->
    if result.tabConnections then tabconnections = result.tabConnections
    else tabconnections = []
    loadBookmarks()
    #loadHistory()
  
  
  $("#configbar > button").click () -> 
    $(this).toggleClass("buttonactivestate")
    console.log $(this).context.className
    switch $(this).context.className.split(" ")[0]
      when "c1" then $("#historycontent .c1").toggle("fast") #console.log "1"
      when "c2" then $("#historycontent .c2").toggle("fast") #console.log "2"
      when "c3" then $("#historycontent .c3").toggle("fast") #console.log "3"
      when "c0" then $("#historycontent .c0").toggle("fast") #console.log "3"
    
    
  null




reload = () ->
  $('#historycontent').empty()
  siteHistory = []
  bookMarks = {}
  visitIdArray = []
  siteContext = []
  v_max = 0
  blocks = {}
  refToBlock = []
  blockStyle = []
  blockId = 0
  refMissing = []
  urltoSid = {}
  findOutlater = []
  shortUrls = []
  loadBookmarks()











# 1: Load all Bookmarks and save them in bookmarks[]
loadBookmarks = () ->
  todo = 0
  chrome.bookmarks.getTree (bookmarkTreeNodes) ->
    #console.log bookmarkTreeNodes
    bfolder = ""
    morebms = bookmarkTreeNodes[0].children[1].children;
    for n in morebms
      if n.title is "conmarks"
        bfolder = n.title;
        for m in n.children
          todo++
          if m.children?
            for o in m.children 
              bookMarks[o.url] = context:m.title, id:o.title.split("___", 1)[0], bid:o.id
            todo--
          else
            bookMarks[m.url] = context:undefined, id:m.title.split("___", 1)[0], bid:m.id
            todo-- 
    if !bfolder
      chrome.bookmarks.create {'parentId': "2", 'title': 'conmarks'}, (bookmarkTreeNodes) -> null

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
  
  console.log tabconnections
  
  chrome.history.search {text:filter.query, startTime:starttime, endTime:endtime, maxResults:filter.results}, (historyItems) ->
    #historyItems.forEach (site) ->
    (historyItems.reverse()).forEach (site) ->
      processed++
      chrome.history.getVisits {url:site.url}, (visitItems) -> processVisitItems(site, visitItems)
    null
  
processVisitItems = (site, visitItems) ->
  
  id = site.id
  vid = visitItems[visitItems.length-1].visitId
  type = visitItems[visitItems.length-1].transition
  ref = 0 #visitItems[visitItems.length-1].referringVisitId
  relevance = visitItems.length
  
  

  ###----------------------------------------------------------------------------------------###
  #console.log visitItems.length
  referrer = []
  noblockreferred = true
  blockofreferredsid = 0
  
  for i in visitItems
    
    
    if tabconnections[i.visitId]?
      ref = tabconnections[i.visitId]
    else if i.referringVisitId isnt "0" 
      referrer.push i.referringVisitId
      ref = i.referringVisitId
   
    console.log i.visitId + " - " + ref
   
    #if refToBlock[i.referringVisitId]? and i.referringVisitId isnt "0"
      #findOutlater[refToBlock[i.referringVisitId]] = i.referringVisitId
   
    # ist diese visitId schon als Referrer vorgemerkt ?
    # wenn ja die Seite (aktuelle VisitId) zum schon bestehenden Block hinzufügen
    if refToBlock[ref]?
      noblockreferred = false;
      blockofreferredsid = refToBlock[ref]
      console.log blockofreferredsid
   
    #if ref isnt undefined
    refToBlock[i.visitId] = id
   
    visitIdArray[i.visitId] = sid:id, ref:ref, vid:i.visitId   


    ###
    # die ReferrerId auf die Aktuelle SeitenId verlinken
    # PROBLEM nur eine ReferrerId möglich
    if refToBlock[i.referringVisitId]? and i.referringVisitId isnt "0"
      findOutlater[refToBlock[i.referringVisitId]] = i.referringVisitId
    
    refToBlock[i.referringVisitId] = id
    # ist diese visitId schon als Referrer vorgemerkt ?
    # wenn ja die Seite (aktuelle VisitId) zum schon bestehenden Block hinzufügen
    if refToBlock[i.visitId]?
      noblockreferred = false;
      blockofreferredsid = refToBlock[i.visitId]
    ###
  
  ###----------------------------------------------------------------------------------------###
  

    
  if referrer.length is 0
    refMissing[id] = site.url
  
  if noblockreferred or !blocks[blockofreferredsid]
    blocks[id] = blockId
    blockId++
  else blocks[id] = blocks[blockofreferredsid]

  urltoSid[site.url] = id
  
  SiteItem = sid:site.id, vid:vid, url:site.url, title:site.title, type:type, ref:ref, relevance:relevance
  siteHistory[id] = SiteItem
  
  processed--;
  if processed is 0 then processTabConnections()
     










processTabConnections = () ->
  
  #console.log tabconnections
  #console.log visitIdArray
  #console.log refArray
  #console.log siteHistory
  #console.log refMissing
  
  
  
  
  ## Interpolate Missing Tablinks
  processIt = 0;
  for tc in tabconnections
    processIt++;

    for sid,v_url of refMissing
      if v_url is tc.url
        
        ref_id = urltoSid[tc.refurl]
        siteHistory[sid].nav = tc.nav
        
        if ref_id isnt undefined
          oldblockindex = blocks[sid]
          newblockindex = blocks[ref_id]
          blocks[sid] = newblockindex
          
          for kk,val of blocks 
            if val is oldblockindex
              blocks[kk] = newblockindex        
    processIt--;  
    
    
  
  ## Refresh Blocks of double Reference-links
  for key,val of findOutlater
    if val isnt "0"
      oldblockindex = blocks[key]
      newblockindex = blocks[refToBlock[val]]         
      #console.log oldblockindex + " " + newblockindex
      blocks[key] = newblockindex
      
      for kk,val of blocks 
        if val is oldblockindex
          blocks[kk] = newblockindex
    

    
  for key,item of siteHistory
    item.block = blocks[key]


  
  for key,item of visitIdArray
    processIt++;  
    if visitIdArray[item.ref]?
      item.sidref = visitIdArray[item.ref].sid
      # für die ausgabe der benachbarten seitenIds
      siteHistory[item.sid].sidref = visitIdArray[item.ref].sid    
    processIt--;

  bookmartise()
  








   

bookmartise = () ->
  
  bprocessed = 0;
  for key,val of siteHistory
    bprocessed++
    bookmark = if bookMarks[val.url]?
      bookMarks[val.url].bid
      val.bookmark = true  
      blockStyle[blocks[key]] = bookMarks[val.url].context

  if bprocessed = filter.results  
    siteHistory.sort (a,b) -> return if a.vid >= b.vid then 1 else -1
    for key,item of siteHistory.reverse()
      specialise(item)      
      
      










specialise = (site) ->

  url = site.url
  title = site.title
  context = undefined
  special = undefined


  if ((url.substr -4) is ".jpg") or ((url.substr -4) is ".png") or ((url.substr -5) is ".jpeg")
    special = "image"
    title = "Abbildung"
  else if (/youtube/.test(url)) && (/watch/.test(url))
    title = title.split("- YouTube")[0]
    if (v_max > 0)
      url = "https://www.youtube.com/embed/" + url.split("v=")[1].split('=')[0].split('&')[0]
      special = "video"
      v_max--
  else if /Google-Suche/.test(title)
    special = "google"
  else if /mail.google.com/.test(url)
    #title = title.split(" - Gmail")[0]
    special = "mail"
  
  title = title.split(" - ")[0]
  title = title.split(" – ")[0]
  shorten = 40
  title = if (title.length > shorten) then (title.substr(0,shorten) + "...") else title
  site.url = url
  site.title = title
  site.special = special
  
  if title is ""
    special = "empty"
    title = url
  else
    renderItem(site)














renderItem = (item) ->
  
  title = item.title
  url = item.url
  sid = item.sid
  vid = item.vid
  type = item.type
  bid = item.bid
  special = item.special
  ref = item.ref
  relevance = item.relevance


  # Panel
  # falls refid auf url des vorgängerszeigt ->verlinken
  panel_div = $ "<div>"
  panel_div.addClass "panel"
  panel_div.addClass type
  if item.nav?
    panel_div.addClass item.nav
  if ref is "0" then panel_div.addClass "refzero"

  if relevance>20  then panel_div.addClass "rel_big"
  else if relevance>5  then panel_div.addClass "rel_some"
  else if relevance>=2  then panel_div.addClass "rel_twice"
    
    
  ## PANELHEADER
  head_div = $ "<div>"
  content_div = $ "<div>"
  content_div.addClass "content"
  head_div.addClass "head"
  favicon = $ "<img>"
  favicon.attr src:"chrome://favicon/"+url
  favicon.addClass "favicon"
  head_div.append $ favicon
  if special isnt "google" and special isnt "empty"
    button1 = $ "<button>"
    button1.text ""
    button1.click () -> bookmarkIt(item, "c1")
    button2 = $ "<button>"
    button2.text ""
    button2.click () -> bookmarkIt(item, "c2")
    button3 = $ "<button>"
    button3.text ""
    button3.click () -> bookmarkIt(item, "c3")
    button1.addClass "c1"
    button2.addClass "c2"
    button3.addClass "c3"    
    head_div.append $ button3
    head_div.append $ button2
    head_div.append $ button1
  clear = $ "<div>"
  clear.addClass "clear"
  head_div.append $ clear

  
  ## Bookmarks und zugehörige Kontexte auszeichnen
  if blockStyle[blocks[item.sid]]?
    context = blockStyle[blocks[item.sid]]
    head_div.addClass context
    panel_div.addClass context
  else 
    panel_div.addClass "c0"
  if item.bookmark isnt undefined
    context += " bookmark"
    content_div.addClass context


  ##content
  link = $ "<a>"
  inhalt = $ "<p>"
  link.attr href:url
  link.addClass "urladress"  
  
  # check Importance of queryresults
  if filter.query isnt ""
    qtl = filter.query.toLowerCase(); ttl = title.toLowerCase(); utl = url.toLowerCase()
    if ttl.indexOf(qtl) < 0 && utl.indexOf(qtl) > 0
      panel_div.addClass "lessimportant"
    else if ttl.indexOf(qtl) < 0 && utl.indexOf(qtl) < 0
      panel_div.addClass "unimportant"
          
  if special is "image" then pic = $ "<img>"; pic.attr src:url.substr(url.search /http/); pic.addClass "imgpreview"; inhalt.append pic; link.append $ inhalt
  else if special is "google" then title = title.split(" - Google-Suche")[0]; inhalt.text title; inhalt.attr id:sid; link.append $ inhalt
  else if special is "video"
    videoframe = $ "<iframe>"; videoframe.addClass "youtubevideo";
    videoframe.attr src:url;  content_div.append videoframe
  else inhalt.text title; inhalt.attr id:sid; link.append $ inhalt

  # Entwicklungsinformationen
  info = $ "<p>"
  info.addClass "devinfo"
  info.text "Block: " + item.block
  info1 = $ "<p>"
  info1.addClass "devinfo"
  info1.text sid + " > " + item.sidref
  info2 = $ "<p>"
  info2.addClass "devinfo"
  info2.text vid + " > " + ref  
  
  
  
  content_div.append $ link
  content_div.append $ info
  content_div.append $ info1
  content_div.append $ info2

  panel_div.addClass special  
  panel_div.append head_div
  panel_div.append $ content_div  
  
  $("#historycontent").append $ panel_div









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
    bookmarkfolder = undefined
    contextfolder = undefined
    
    for sub in folder
      if sub.title is "conmarks"
        bookmarkfolder = sub
    
    for m in sub.children
      if context is m.title
        contextfolder = m
        chrome.bookmarks.create {parentId:m.id, title:newtitle, url:site.url}, ->
        reload()
    
    if contextfolder is undefined
      chrome.bookmarks.create {parentId:sub.id, title:context}, (bookmarkTreeNodes) ->
        console.log bookmarkTreeNodes
        contextfolder = bookmarkTreeNodes
        chrome.bookmarks.create {parentId:contextfolder.id, title:newtitle, url:site.url}, ->
        reload()






