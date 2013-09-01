storedBookmarks = {}
storedContexts = {}
bookMarks = {}
#chrome.storage.local.remove("storedContexts")

loadBookmarks = (callbackFn) ->
  storedBookmarks = {}
  storedContexts = {}
  bookMarks = {}
  chrome.storage.local.get "storedBookmarks", (result) ->
    if result.storedBookmarks
      storedBookmarks = result.storedBookmarks
  # get active Tasks from Storage
  chrome.storage.local.get "storedContexts", (result) ->
    if result.storedContexts
      storedContexts = result.storedContexts
  renderTaskMenu(callbackFn)

renderTaskMenu = (callbackFn) ->
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
    initBookmarkFolder = bookmarkTreeNodes[0].children[0].children;
    bookmarkFolderTitle = ""

    for bookmarkFolder in initBookmarkFolder

      if bookmarkFolder.title is "conmarks"
        bookmarkFolderTitle = bookmarkFolder;

        for m in bookmarkFolder.children

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
            null

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
            bookMarks[m.url] = context:undefined, id:m.title, bid:m.id
      null

    if !bookmarkFolderTitle
      chrome.bookmarks.create {'parentId': "1", 'title': 'conmarks'}, (bookmarkTreeNodes) ->
        chrome.bookmarks.create {'parentId': bookmarkTreeNodes.id, 'title': 'privat'}, (bookmarkTreeNodes) -> null
        chrome.bookmarks.create {'parentId': bookmarkTreeNodes.id, 'title': 'arbeit'}, (bookmarkTreeNodes) -> null
        chrome.bookmarks.create {'parentId': bookmarkTreeNodes.id, 'title': 'uni'}, (bookmarkTreeNodes) -> null
        null

    context_div = $ "<div>"
    context_div.addClass "bcontext"
    context_div.addClass "newcontext"
    head = $ "<h2>"
    head.addClass "newcontext"
    head.text "+"
    context_div.append head
    $("#bookmarklist").append $ context_div
    hideInactiveTasks()
    callbackFn()
    null
  null





hideInactiveTasks = () ->
  for context,v of storedContexts
    button = "button." + context
    content = "div.head." + context + ", div.content."+context+".bookmark"
    $(button).css "background", v.color
    $(content).css "background", v.color
    if(!v.active) then toggleActiveState(context)







toggleActiveState = (context) ->
  toggleContext = ".bcontext." + context
  $(toggleContext).toggleClass("contextactivestate")
  toggleBookmark = "." + context + " .bookmark"
  $(toggleBookmark).toggle("fast")
  contextClass = "#historycontent ." + context
  #contextClass = ".contextgroup."+context
  $(contextClass).toggle("fast")
  null







bookmarkIt = (site, button) ->
  context = button.attr "class"
  url = site.url
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
  null


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
  null

null