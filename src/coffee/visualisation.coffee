window.hv = window.hv || {}
window.hv.Visualisation = () ->


  this.specialise = (site) ->

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
    shorten = 20
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
      content_div.addClass context + " bookmark"#context


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




  toggleActiveState = (context) ->
    toggleContext = ".bcontext." + context
    $(toggleContext).toggleClass("contextactivestate")
    toggleBookmark = "." + context + " .bookmark"
    $(toggleBookmark).toggle("fast")
    contextClass = "#historycontent ." + context
    $(contextClass).toggle("fast")