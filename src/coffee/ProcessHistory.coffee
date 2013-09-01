processed = 0
tabconnections = []

block = 0
lastVid = 0
lastUrl = ""
siteHistory = []
visitIdAufSID = []
blockSum = 0;
blocks = {}
blockStyle = []
idToRef = {}
#idToVid = {}
#blockId = 0





loadHistory = (callbackFn) ->
  block = 0
  lastVid = 0
  lastUrl = ""
  siteHistory = []
  visitIdAufSID = []
  blockSum = 0;
  idToRef = {}
  blocks = {}
  blockStyle = []

  chrome.storage.local.get "tabConnections", (result) ->
    if result.tabConnections then tabconnections = result.tabConnections
    else tabconnections = []
    processHistoryItems(callbackFn)






processHistoryItems = (callbackFn) ->
  console.log filter
  time = filter.time
  processed = 0
  date = new Date()
  daydate = date.getTime()-((((date.getHours()+1) * 60 + date.getMinutes()) * 60 + date.getSeconds() ) * 1000)
  microsecondsPerDay = 1000 * 60 * 60 * 24
  endtime   = daydate - (microsecondsPerDay * (time-1))
  starttime = daydate - (microsecondsPerDay * (30+time))
  chrome.history.search {text:filter.query, startTime:starttime, endTime:endtime, maxResults:filter.results}, (historyItems) ->
    console.log historyItems.length
    (historyItems.reverse()).forEach (site) ->
      processed++
      chrome.history.getVisits {url:site.url}, (visitItems) -> processVisitItems(site, visitItems, callbackFn)





processVisitItems = (site, visitItems, callbackFn) ->
  referrer = vids = []
  id = site.id
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

  ## Grobe Blockbildung
  if type is "link" and (lastVid is ref or lastUrl is site.url.substr(0,10)) then null
  else block++
  lastVid = vid
  lastUrl = site.url.substr(0,10)

  context = ""
  bookmark = undefined
  if bookMarks[site.url]?
    context = bookMarks[site.url].context
    bookmark = bookMarks[site.url].bid

  tab = if tabArray[site.url]? then tabArray[site.url] else ""

  siteItem = sid:id, vid:vid, url:site.url, title:site.title, type:type, ref:ref, relevance:count, time:time, block:block, context:context, tab:tab, bid:bookmark
  siteHistory[id] = siteItem
  #logInfo([site.url.substr(0,40), id, vid, ref, type, block, bookmark])

  processed--;
  if processed is 0
    blockSum = block
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