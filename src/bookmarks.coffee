
bookmark = (c_panel, bid, vid, url, title, context) ->
  
  preclass = (c_panel.attr "class")
  c_panel.removeClass()  
  if preclass is "" then preclass = undefined
  
  #console.log (c_panel.attr "class")
  #console.log (bid)
  #console.log preclass
  #console.log (context)
      
  if preclass? then chrome.bookmarks.remove(preclass.split(" ")[1], null)
  if preclass is undefined or ( preclass? and preclass.split(" ")[0] isnt context) 
    chrome.bookmarks.getTree (bookmarkTreeNodes) ->
      morebms = bookmarkTreeNodes[0].children[1].children;
      # idlänge muss genau sein
      newtitle = "#{vid}___#{title}"
      for n in morebms
       if n.title is "conmarks"
        if context is undefined then chrome.bookmarks.create {parentId:n.id, title:newtitle, url:url} else
          for m in n.children
            if context is m.title then chrome.bookmarks.create {parentId:m.id, title:newtitle, url:url}
    c_panel.addClass context
    chrome.bookmarks.getRecent 1, (bookmarkTreeNodes) ->
      c_panel.addClass bookmarkTreeNodes[0].id; console.log "neu"+bookmarkTreeNodes[0].id




### 
getBookmarks = () ->
  chrome.bookmarks.getTree (bookmarkTreeNodes) ->
    morebms = bookmarkTreeNodes[0].children[1].children;
    gotit = false
    for n in morebms
     if n.title is "conmarks" then gotit = true; return n
    if gotit is false then chrome.bookmarks.create {parentId:"2", title:"conmarks"}
###