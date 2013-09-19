processed = 0
tabconnections = []
lastVid = 0
lastUrl = ""
siteHistory = []
visitIdAufSID = []
idToRef = {}
urltoblock = {}
#idToVid = {}
#blockId = 0
block_counter = 0
block_set = 0
blockSum = 0
blocks = []
#blockStyle = []
lastTitle = ""
filterArray = ["adf.ly"]


loadHistory = (callbackFn) ->

  processed = 0
  tabconnections = []
  lastVid = 0
  lastUrl = ""
  siteHistory = []
  visitIdAufSID = []
  idToRef = {}
  urltoblock = {}
  block_counter = 0
  block_set = 0
  blockSum = 0
  blocks = []
  #blockStyle = []

  chrome.storage.local.get "tabConnections", (result) ->
    if result.tabConnections then tabconnections = result.tabConnections
    else tabconnections = []
    processHistoryItems(callbackFn)






processHistoryItems = (callbackFn) ->
  time = filter.time
  processed = 0
  date = new Date()
  daydate = date.getTime()-((((date.getHours()+1) * 60 + date.getMinutes()) * 60 + date.getSeconds() ) * 1000)
  microsecondsPerDay = 1000 * 60 * 60 * 24
  endtime   = daydate - (microsecondsPerDay * (time-1))
  starttime = daydate - (microsecondsPerDay * (30+time))
  chrome.history.search {text:filter.query, startTime:starttime, endTime:endtime, maxResults:filter.results}, (historyItems) ->
    (historyItems.reverse()).forEach (site) ->
      processed++
      chrome.history.getVisits {url:site.url}, (visitItems) -> processVisitItems(site, visitItems, callbackFn)





processVisitItems = (site, visitItems, callbackFn) ->
  referrer = vids = []
  id = site.id
  url = site.url


  #Vorfiltern
  if /data:/.test(url)
    null
    #console.log site
  else

    vid = visitItems[visitItems.length-1].visitId
    ref = visitItems[visitItems.length-1].referringVisitId
    type = visitItems[visitItems.length-1].transition
    time = visitItems[visitItems.length-1].visitTime
    count = site.visitCount #visitItems.length

    for i in visitItems
      if i.visitId > vid-300  # Anzahl einschränken
        # Fehlende Verlinkung bei Tabs ergänzen
        if tabconnections[i.visitId]? then referrer.push tabconnections[+i.visitId]
        if i.referringVisitId isnt "0" then referrer.push i.referringVisitId
        #vids.push i.visitId
        visitIdAufSID[i.visitId] = id

    idToRef[id] = referrer #idToVid[id] = vids



    testurl = url.split("//")[1]
    #if testurl.substr(0,3) is "www" then testurl = testurl.split("www.")[1]
    url = testurl.substr(0,10)


    # Grobe Blockbildung
    # linkseite mit gefundenen Ref oder URL-Ahnlichkeit zum Vorgänger
    if (type is "link" or type is "form_submit") and (lastVid is ref or lastUrl is url)
      urltoblock[url] = block_set
    else
      # existiert eine Url-Ähnlichkeit zu einem entfernteren Vorgänger
      if urltoblock[url]? and url isnt "www.google" and url isnt "www.youtub" #and (type isnt "typed" and type isnt "keyword" and type isnt "generated")
        block_set = urltoblock[url]
      else
        block_counter++
        blocks[block_counter] = {"id":block_counter,"context":"","time":"","processed":false,"google":false}
        if /google/.test(url) then blocks[block_counter].google = true
        block_set = block_counter
        urltoblock[url] = block_set

    lastVid = vid
    lastUrl = url

    # Lesezeicheninformationen
    context = ""; bookmark = undefined
    if bookMarks[site.url]?
      context = bookMarks[site.url].context
      bookmark = bookMarks[site.url].bid
      blocks[block_set].context = context

    blocks[block_set].time = time

    # Tabinformationen
    tab = if tabArray[site.url]? then tabArray[site.url] else ""

    # Array für die History anlegen
    if lastTitle isnt site.title and !(jQuery.inArray( url.substr(0, 6), filterArray ) >= 0)
      siteItem = sid:id, vid:vid, url:site.url, title:site.title, type:type, ref:ref, relevance:count, time:time, block:block_set, context:context, tab:tab, bid:bookmark
      siteHistory[id] = siteItem
    else null #console.log url.substr(0,6)


    lastTitle = site.title
    #logInfo([site.title.substr(0,40), id, vid, ref, type, block_set])

  processed--;
  if processed is 0
    blockSum = block_counter
    #console.log blocks
    callbackFn()














logInfo = (infoarray)->
  siteinfo = $ "<div>"
  for k,i of infoarray
    info = $ "<div>"
    info.text i
    info.addClass "infotext"
    if k == "0" then info.addClass "title"
    siteinfo.append $ info
  $("#historycontent").append $ siteinfo

###
createBlocks = () ->
  block = 1
  for id,val of siteHistory
    processed++
    for v in idToRef[id]
      processed++
      if visitIdAufSID[v]?
        if siteHistory[visitIdAufSID[v]].block != 0 #block wird geerbt
          if val.block != 0
            for s in siteHistory # noch berücksichtigen dass andere mitgenommen werden
              if s.block == val.block then s.block = siteHistory[visitIdAufSID[v]].block
          val.block = siteHistory[visitIdAufSID[v]].block
        else
          if val.block == 0
            siteHistory[visitIdAufSID[v]].block = val.block = block #gibt nix zu erben man braucht einen neuen
            block++
          else
            siteHistory[visitIdAufSID[v]].block = val.block #gibt nix & man hat schon -> in die andere richtung vererben
      processed--
    if val.block is 0 or idToRef[id].length is 0
      val.block = block
      block++
    processed--
  if processed is 0
    for k,i of siteHistory
      logInfo([i.title.substr(0,40), i.sid, i.vid, i.ref, i.type, i.block])
###