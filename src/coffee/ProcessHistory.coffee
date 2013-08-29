window.hv = window.hv || {}
window.hv.ProcessHistory = (filter) ->

  processed = 0
  tabconnections = []

  siteHistory = {}
  idToRef = {}
  idToVid = {}

  visitIdAufSID = []
  blockId = 0
  blocks = {}
  blockStyle = []

  this.loadHistory = () ->

    chrome.storage.local.get "tabConnections", (result) ->
      if result.tabConnections then tabconnections = result.tabConnections
      else tabconnections = []
      processHistoryItems()


  processHistoryItems = () ->
    time = filter.time
    mode = filter.mode
    processed = 0
    date = new Date()
    daydate = date.getTime()-((((date.getHours()+1) * 60 + date.getMinutes()) * 60 + date.getSeconds() ) * 1000)
    microsecondsPerDay = 1000 * 60 * 60 * 24
    endtime   = daydate - (microsecondsPerDay * (time-1))
    starttime = daydate - (microsecondsPerDay * (30+time))
    chrome.history.search {text:filter.query, startTime:starttime, endTime:endtime, maxResults:filter.results}, (historyItems) ->
      (historyItems).forEach (site) ->
        processed++
        chrome.history.getVisits {url:site.url}, (visitItems) -> processVisitItems(site, visitItems)
      null


  processVisitItems = (site, visitItems) ->
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

    idToRef[id] = referrer
    #idToVid[id] = vids
    #logInfo([site.title, id, vid, ref, type])

    siteItem = sid:id, vid:vid, url:site.url, title:site.title, type:type, ref:ref, relevance:count, time:time, block:0
    siteHistory[id] = siteItem
    processed--; if processed is 0 then createBlocks()
    null


  createBlocks = () ->

    #console.log idToRef
    #console.log idToVid
    block = 1

    for k,val of siteHistory
      processed++
      id = val.sid
      vid = val.vid
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
      processed--


    console.log block

    if processed is 0
      for k,i of siteHistory
        logInfo([i.url.substr(0,40), i.sid, i.vid, i.ref, i.type, i.block])

    null







  addContextClasses = () ->
    ###
    bmsProcessed = 0;
    for key,val of siteHistory
      bmsProcessed++
      bookmark = if bookMarks[val.url]?
        #console.log blocks[key]
        bookMarks[val.url].bid
        val.bookmark = true
        blockStyle[blocks[key]] = bookMarks[val.url].context


    if bmsProcessed = filter.results
      # Nach Aktualität sortieren und daraufhin Rendern
      siteHistory.sort (a,b) -> return if a.vid <= b.vid then 1 else -1
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
          if(!v.active) then toggleActiveState(context)
    ###
    null



  logInfo = (infoarray)->
    siteinfo = $ "<div>"
    for k,i of infoarray
      info = $ "<div>"
      info.text i
      info.addClass "infotext"
      if k == "0" then info.addClass "title"
      siteinfo.append $ info
    $("#historycontent").append $ siteinfo

  null
