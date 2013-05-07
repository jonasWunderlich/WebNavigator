# Maximum of Videos to show
v_max = 0
# Default Settings of filtering the View
filter = results:50, time:0, query:"", mode:"none"
context = "empty"
hSlider = 0
processed = 0

# Temporaily Save all Bookmarks
storedBookmarks = {} # !!!!!!!!!!!!!!!!!!!
storedContexts = {} # !!!!!!!!!!!!!!!!!!!
bookMarks = {}
# Working Array
siteHistory = []
# Missing Tabconnections
tabconnections = {}


# Blockvariablen
blockId = 0
blocks = {}
visitId_pointo_SiteId = []
#visitIdArray = {}
blockStyle = []



###
chrome.storage.local.remove("tabs")
chrome.storage.local.remove("tabConnections")
chrome.storage.local.remove("storedBookmarks")
chrome.storage.local.remove("storedContexts")
###

reload = () ->
  chrome.storage.local.set "storedBookmarks":storedBookmarks
  $('#historycontent').empty()
  $('#bookmarklist').empty()
  siteHistory = []
  bookMarks = {}
  tabconnections = {}
  
  v_max = 0
  
  blockId = 0
  blocks = {}
  visitId_pointo_SiteId = []
  #visitIdArray = []
  blockStyle = []
 
  loadBookmarks()







$(document).ready ->   
  chrome.storage.local.get "query", (result) ->
    if result.query?
      filter.query = result.query
      $("#search").val result.query
      
  chrome.storage.local.get "hSlider", (result) ->
    if result.hSlider?
      query_slider.x = result.hSlider
      
  chrome.storage.local.get "storedBookmarks", (result) ->
    if result.storedBookmarks
      storedBookmarks = result.storedBookmarks
  chrome.storage.local.get "storedContexts", (result) ->
    if result.storedContexts
      storedContexts = result.storedContexts
      
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
  
  $("#bookmarklist").on "click", "h2", ->
    context = $(this).context.className.split(" ")[0]
    toggleActiveState(context)
    if storedContexts[context].active
      storedContexts[context].active = false
    else
      storedContexts[context].active = true
    chrome.storage.local.set "storedContexts":storedContexts
    
  null




toggleActiveState = (context) ->
  toggleContext = ".bcontext." + context
  $(toggleContext).toggleClass("contextactivestate")
  toggleBookmark = "." + context + " .bookmark"
  $(toggleBookmark).toggle("fast")
  contextClass = "#historycontent ." + context
  $(contextClass).toggle("fast")

  
  










# 1: Load all Bookmarks and save them in bookmarks[]
loadBookmarks = () ->
  
  # no context header
  context_div = $ "<div>"
  context_div.addClass "bcontext"
  context_div.addClass "nocontext"
  head = $ "<h2>"
  head.addClass "nocontext"
  head.text "kontextlos"
  context_div.append head
  $("#bookmarklist").append $ context_div
  
  counter = 0
    
  chrome.bookmarks.getTree (bookmarkTreeNodes) ->
    bfolder = ""
    morebms = bookmarkTreeNodes[0].children[0].children;
    
    console.log bookmarkTreeNodes
    
    for n in morebms
      if n.title is "conmarks"
        bfolder = n.title;
        for m in n.children
          
          contextColor = "9F0"
          if !storedContexts[m.title] 
            storedContexts[m.title] = color:contextColor, active:true
          else
            contextColor = storedContexts[m.title].color
 
          context_div = $ "<div>"
          context_div.addClass "bcontext"
          context_div.addClass m.title
          head = $ "<div>"
          head.css "background", contextColor
          head.addClass m.title
          
          title = $ "<h2>"
          title.css "background", contextColor
          title.addClass m.title
          title.text m.title
          
          color = $ "<input>"
          color.attr "id",  m.title
          color.attr "name", m.title
          color.attr "type","text"
          color.attr "value", contextColor
          
          head.append color
          head.append title
          context_div.append head

          color.colorPicker onColorChange: (id, newValue) ->
            newhead = ".bcontext." + id + " h2"
            newhead2 = ".bcontext ." + id
            $(newhead).css "background", newValue
            $(newhead2).css "background", newValue
            button = "button." + id
            content = "div.head." + id + ", div.content."+id+".bookmark" 
            $(button).css "background", newValue
            $(content).css "background", newValue
            storedContexts[id].color = newValue
            chrome.storage.local.set "storedContexts":storedContexts
          
          #context_div.append head
          $("#bookmarklist").append $ context_div
          
          counter++
          
          if m.children?
            for o in m.children
  
              bookMarks[o.url] = context:m.title, id:o.title, bid:o.id
              if !storedBookmarks[o.url] then storedBookmarks[o.url] = bid:o.id, visitTime:o.dateAdded
              
              bm_div = $ "<div>"
              bm_div.addClass "bookmark" 
              favicon = $ "<img>"
              favicon.attr src:"chrome://favicon/"+o.url
              favicon.addClass "favic"
              bm_div.append $ favicon                  
              bmtitle = $ "<a>"
              bmtitle.attr "href", o.url
              bmtitle.text o.title
              bm_div.append bmtitle
              context_div.append bm_div
          else
            #console.log m
            bookMarks[m.url] = context:undefined, id:m.title, bid:m.id
          
          #console.log storedContexts[m.title].active
          #console.log m.title
          #if(!storedContexts[m.title].active) then toggleActiveState(m.title)

    if !bfolder
      chrome.bookmarks.create {'parentId': "1", 'title': 'conmarks'}, (bookmarkTreeNodes) -> 
        chrome.bookmarks.create {'parentId': bookmarkTreeNodes.id, 'title': 'privat'}, (bookmarkTreeNodes) -> null
        chrome.bookmarks.create {'parentId': bookmarkTreeNodes.id, 'title': 'arbeit'}, (bookmarkTreeNodes) -> null
        chrome.bookmarks.create {'parentId': bookmarkTreeNodes.id, 'title': 'uni'}, (bookmarkTreeNodes) -> null
  
  
    context_div = $ "<div>"
    context_div.addClass "bcontext"
    context_div.addClass "newcontext"
    head = $ "<h2>"
    head.addClass "newcontext"
    head.text "+"
    context_div.append head
    $("#bookmarklist").append $ context_div 

  loadHistory()













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
  
  chrome.history.search {text:filter.query, startTime:starttime, endTime:endtime, maxResults:filter.results}, (historyItems) ->
    (historyItems.reverse()).forEach (site) ->
      processed++
      chrome.history.getVisits {url:site.url}, (visitItems) -> processVisitItems(site, visitItems)
    null
  
  
  
  
  
  
  
  
  

  
processVisitItems = (site, visitItems) ->
  
  id = site.id
  vid = visitItems[visitItems.length-1].visitId
  type = visitItems[visitItems.length-1].transition
  time = visitItems[visitItems.length-1].visitTime
  ref = visitItems[visitItems.length-1].referringVisitId
  relevance = visitItems.length
  
  
  
  ###----------------------------------------------------------------------------------------###
  refs = ""
  referrer = []
  noblockreferred = true
  referringSiteId = ""
  for i in visitItems
    
    # Fehlende Verlinkung bei Tabs ergänzen
    if tabconnections[i.visitId]? #and ref is "0" 
      type = "tab"
      # eigentlich nicht notwendigerweise in der schleife aufrufen
      ref = tabconnections[i.visitId]
      referrer.push tabconnections[i.visitId]

    # ist der Referrer bereits als VisitId eingetragen ?
    # wenn ja die dem Ref zugehörige SiteId ermitteln
    if visitId_pointo_SiteId[ref]?
      noblockreferred = false;
      referringSiteId = visitId_pointo_SiteId[ref]
    
    # Verweis der VisitId auf die Pageid merken
    visitId_pointo_SiteId[i.visitId] = id
    #visitIdArray[i.visitId] = sid:id, ref:ref, vid:i.visitId
    
    if i.referringVisitId isnt "0"
      #ref += i.referringVisitId + " "
      referrer.push i.referringVisitId
    
  ###----------------------------------------------------------------------------------------###  

  # falls keine Referenz in der Auswahl ermittelt werden konnte neuen Block hinzufügen
  if noblockreferred #or !blocks[referringSiteId]
    blocks[id] = blockId
    blockId++
    #console.log site.title
    #console.log referrer.length
    if referrer.length > 0 then null
      #console.log site.title
      #console.log referrer
  else blocks[id] = blocks[referringSiteId]
  
  
  
  
  SiteItem = sid:site.id, vid:vid, url:site.url, title:site.title, type:type, ref:ref, relevance:relevance, block:blockId, sidref:referringSiteId, time:time
  
  bookmark = if bookMarks[site.url]?
    #SiteItem["bookmark"] = true
    null
    #blockStyle[blockId] = bookMarks[site.url].context
    #SiteItem["bookmark"] = true
    #console.log blockStyle
    #console.log blockId
    #console.log blocks
  
  siteHistory[id] = SiteItem
  
  processed--;
  if processed is 0 then bookmartise()
     




bookmartise = () ->
    
  bmsProcessed = 0;
  for key,val of siteHistory
    bmsProcessed++
    bookmark = if bookMarks[val.url]?
      #console.log blocks[key]
      bookMarks[val.url].bid
      val.bookmark = true  
      blockStyle[blocks[key]] = bookMarks[val.url].context
      
  ###
      for (key in findOutlater) {
        val = findOutlater[key];
        if (val !== "0") {
          oldblockindex = blocks[key];
          newblockindex = blocks[visitId_pointo_SiteId[val]];
          blocks[key] = newblockindex;
          for (kk in blocks) {
            val = blocks[kk];
            if (val === oldblockindex) {
              blocks[kk] = newblockindex;
            }
          }
        }
      }
  ###
  
  if bmsProcessed = filter.results  
    # Nach Aktualität sortieren und daraufhin Rendern
    siteHistory.sort (a,b) -> return if a.vid >= b.vid then 1 else -1
    count = 0
    for key,item of siteHistory.reverse()
      specialise(item)
      count++
    
    if count = filter.results
      for context,v of storedContexts
        button = "button." + context
        content = "div.head." + context + ", div.content."+context+".bookmark" 
        $(button).css "background", v.color
        $(content).css "background", v.color
        console.log context
        if(!v.active) then toggleActiveState(context)

      


















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
    site.title = url
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
    
    createButton = (item,c) ->
      button = $ "<button>"
      #button.css "background", v.color
      button.addClass c
      button.text ""
      button.on "click", -> bookmarkIt(item, c)
      head_div.append $ button
    
    for c,v of storedContexts
      createButton(item,c)
       
  clear = $ "<div>"
  clear.addClass "clear"
  head_div.append $ clear

  
  ## Bookmarks und zugehörige Kontexte auszeichnen
  if blockStyle[blocks[item.sid]]?
    context = blockStyle[blocks[item.sid]]
    head_div.addClass context
    panel_div.addClass context
  else 
    panel_div.addClass "nocontext"
  if item.bookmark isnt undefined
    context += " bookmark"
    content_div.addClass context# + " bookmark"#context


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
  console.log context
  url = site.url
  context = context
  if bookMarks[url]?
    if bookMarks[url].context is context
      chrome.bookmarks.remove storedBookmarks[url].bid, ->
        delete storedBookmarks[site.url]
        reload()
    else if bookMarks[url].context isnt undefined
      chrome.bookmarks.remove storedBookmarks[url].bid, ->
        delete storedBookmarks[site.url]
        createBookmark site, context 
  else
    createBookmark site, context
  
  
createBookmark = (site, context) ->
  chrome.bookmarks.getTree (bookmarkTreeNodes) ->
    folder = bookmarkTreeNodes[0].children[0].children;
    newtitle = "#{site.vid}___#{site.title}"
    bookmarkfolder = undefined
    contextfolder = undefined
    
    for sub in folder
      if sub.title is "conmarks"
        bookmarkfolder = sub
    
    for m in bookmarkfolder.children
      if context is m.title
        contextfolder = m
        chrome.bookmarks.create {parentId:m.id, title:site.title, url:site.url}, (BookmarkTreeNode) ->
          storedBookmarks[site.url] = bid:BookmarkTreeNode.id, visitTime:site.time
          reload()
    
    if contextfolder is undefined
      chrome.bookmarks.create {parentId:bookmarkfolder.id, title:context}, (bookmarkTreeNodes) ->
        storedContexts[context] = color:"#fff".id
        console.log bookmarkTreeNodes
        contextfolder = bookmarkTreeNodes
        chrome.bookmarks.create {parentId:contextfolder.id, title:site.title, url:site.url}, ->
          reload()
  
    
