specialise = (site, divToGo) ->

  url = site.url
  title = site.title
  special = undefined

  if (((url.substr -4).toLowerCase() is ".gif") or (url.substr -4).toLowerCase() is ".jpg") or ((url.substr -4).toLowerCase() is ".png") or ((url.substr -5).toLowerCase() is ".jpeg")
    special = "image"
    title =  url.split(/[/]+/).pop().replace(/_/g," ") #"Abbildung"
  if (((url.substr -4).toLowerCase() is ".pdf") or (url.substr -4).toLowerCase() is ".txt") or ((url.substr -4).toLowerCase() is ".doc") or ((url.substr -5).toLowerCase() is ".docx")
    special = "document"
    title = url.split(/[/]+/).pop().replace(/_/g," ") #"Dokument"
  else if (/youtube/.test(url)) && (/watch/.test(url)) && !(/user/.test(url)) && !(/www.google/.test(url))
    title = title.split("- YouTube")[0]
    if (v_max > 0)
      url = "https://www.youtube.com/embed/" + url.split("v=")[1].split('=')[0].split('&')[0]
      special = "y_video"
      v_max--
  else if /Google-Suche/.test(title) then   special = "google"
  else if /mail.google.com/.test(url) then  special = "mail"

  site.title = title
  site.url = url
  site.special = special

  if title is ""
    special = "empty"
  else
    null
  renderItem(site, divToGo)
  null

thelastURL = ""
thelastTitle = ""

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
  panel_div = $ "<div>"

  if (thelastURL.substr 0, thelastURL.length-3) is (url.substr  0, url.length-3) or thelastTitle is title
    panel_div.addClass "stacking"
  thelastURL = url
  thelastTitle = title

  panel_div.addClass "panel"
  panel_div.addClass type
  panel_div.addClass special
  if item.nav? then  panel_div.addClass item.nav
  if ref is "0" then panel_div.addClass "refzero"
  if relevance>20       then panel_div.addClass "rel_big"
  else if relevance>5   then panel_div.addClass "rel_some"
  else if relevance>=2  then panel_div.addClass "rel_twice"



  # Content besteht aus Header+Inhalt
  content_div = $ "<div>"
  content_div.addClass "content"
  # PANELHEADER
  head_div = $ "<div>"
  head_div.addClass "head"
  # INHALT
  info_div = $ "<div>"
  info_div.addClass "infocontent"

  ## TABReiter
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

  # Favicon
  favicon = $ "<img>"
  favicon.attr src:"chrome://favicon/"+url
  favicon.addClass "favicon"
  head_div.append $ favicon
  # BOOKMARKBUTTONS
  #createButtons(head_div, special, item)
  #addClearDiv(head_div)

  head_div.attr "vid", item.vid
  head_div.attr "url", item.url
  head_div.attr "title", item.title
  head_div.attr "time", item.time


  ## Bookmarks und zugehörige Kontexte auszeichnen
  if item.bid isnt undefined
    info_div.attr "bookmark", item.bid
    info_div.addClass "bookmark"
    info_div.css "background", storedContexts[item.context].color


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
  else if special is "y_video"
    videoframe = $ "<iframe>"; videoframe.addClass "youtubevideo";
    videoframe.attr src:url;  info_div.append videoframe
  else inhalt.text shortenTitle(title,url); inhalt.attr id:sid; link.append $ inhalt

  info_div.append $ link
  # Entwicklungsinformationen
  #addDevInfo(info_div, ["Block "+item.block, sid+" > "+item.sidref, vid+" > "+ref])

  content_div.append head_div
  content_div.append info_div
  panel_div.append $ content_div
  #$("#historycontent").append $ panel_div
  divToGo.append $ panel_div




shortenTitle = (title, url) ->
  shorten = 40
  title = title.split(" - ")[0]
  title = title.split(" – ")[0]
  title = if (title.length > shorten) then (title.substr(0,shorten) + "...") else title
  if title is ""
    title = url.substr(0,shorten) + "..."
  return title


addClearDiv = (div) ->
  clear = $ "<div>"
  clear.addClass "clear"
  div.append $ clear


createButtons = (head_div, special,item) ->
  del = $ "<button>"
  del.addClass "delete"
  del.attr "title", "delete"
  del.text "X"
  del.on "click", ->
    chrome.history.deleteUrl {url:item.url}, ->
      head_div.parent().parent().remove()
  head_div.append $ del

  if special isnt "google" and special isnt "empty"
    for c,v of storedContexts
      if c isnt "nocontext"
        button = $ "<button>"
        button.css "background", v.color
        button.addClass c
        button.attr "title", c
        button.text ""
        button.on "click", -> bookmarkIt(item, $(this))
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

