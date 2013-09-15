specialise = (site, divToGo) ->

  url = site.url
  title = site.title
  context = undefined
  special = undefined
  console.log "dfg" v_max

  if ((url.substr -4) is ".jpg") or ((url.substr -4) is ".png") or ((url.substr -5) is ".jpeg")
    special = "image"
    title = "@"
  else if (/youtube/.test(url)) && (/watch/.test(url))
    console.log v_max
    title = title.split("- YouTube")[0]
    if (v_max > 0)
      url = "https://www.youtube.com/embed/" + url.split("v=")[1].split('=')[0].split('&')[0]
      special = "yvideo"
      v_max--
  else if /Google-Suche/.test(title)
    special = "google"
  else if /mail.google.com/.test(url)
    special = "mail"

  title = title.split(" - ")[0]
  title = title.split(" – ")[0]
  shorten = 20
  title = if (title.length > shorten) then (title.substr(0,shorten) + "...") else title
  site.url = url
  site.title = title
  site.special = special

  if title is ""
    special = "empty"
    site.title = url #.substr(0,shorten) + "..."
    #renderItem(site, divToGo)
  else
    null
    #renderItem(site, divToGo)
  null


renderItem = (item, divToGo) ->

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
  panel_div.addClass special


  ## PANELHEADER
  content_div = $ "<div>"
  head_div = $ "<div>"
  info_div = $ "<div>"
  content_div.addClass "content"
  info_div.addClass "infocontent"

  head_div.addClass "head"

  if item.tab isnt ""
    tabhead = $ "<div>"
    tabhead.addClass "tabbutton"
    panel_div.addClass "itsatab"
    tabhead.attr "tabid", item.tab
    tabhead.on "click", ->
      #console.log $(this).attr "tabid" # $(this)
      chrome.tabs.remove item.tab
      tabhead.removeClass "tabbutton"
      panel_div.removeClass "itsatab"
    #highlightInfo = 0, item.tab
    info_div.click ->
      chrome.tabs.get item.tab, (geTab) ->
        chrome.tabs.highlight {windowId:geTab.windowId, tabs:geTab.index}, ->
    panel_div.append $ tabhead
  else
    notabhead = $ "<div>"
    notabhead.addClass "notab"
    panel_div.append $ notabhead

  favicon = $ "<img>"
  favicon.attr src:"chrome://favicon/"+url
  favicon.addClass "favicon"
  head_div.append $ favicon

  # BOOKMARKBUTTONS
  createButtons(head_div, special, item)
  addClearDiv(head_div)



  ## Bookmarks und zugehörige Kontexte auszeichnen
  #console.log item.bookmark
  if blockStyle[blocks[item.sid]]?
    context = blockStyle[blocks[item.sid]]
    head_div.addClass context
    panel_div.addClass context
  else
    panel_div.addClass "nocontext"
  if item.bookmark isnt undefined
    context += " bookmark"
    info_div.addClass context + " bookmark"#context


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


  if special is "image"
    content_div.css "background", "url("+ url.substr(url.search /http/) + ") 50% 20% "


  if special is "google" then title = title.split(" - Google-Suche")[0]; inhalt.text title; inhalt.attr id:sid; link.append $ inhalt
  else if special is "yvideo"
    videoframe = $ "<iframe>"; videoframe.addClass "youtubevideo";
    videoframe.attr src:url;  info_div.append videoframe
  else inhalt.text title; inhalt.attr id:sid; link.append $ inhalt

  info_div.append $ link
  # Entwicklungsinformationen
  addDevInfo(info_div, ["Block "+item.block, sid+" > "+item.sidref, vid+" > "+ref])

  content_div.append head_div
  content_div.append info_div
  panel_div.append $ content_div
  #$("#historycontent").append $ panel_div
  divToGo.append $ panel_div







addClearDiv = (div) ->
  clear = $ "<div>"
  clear.addClass "clear"
  div.append $ clear


createButtons = (head_div, special,item) ->
  if special isnt "google" and special isnt "empty"
    for c,v of storedContexts
      button = $ "<button>"
      button.css "background", v.color
      button.addClass c
      button.text ""
      button.on "click", -> bookmarkIt(item, c)
      if !storedContexts[c].active
        button.hide()
      head_div.append $ button


addDevInfo = (div, a) ->
  for i in a
    info = $ "<p>"
    info.addClass "devinfo"
    info.text i
    div.append $ info
  null

