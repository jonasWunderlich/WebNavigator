

    

### 
getBookmarks = () ->
  chrome.bookmarks.getTree (bookmarkTreeNodes) ->
    morebms = bookmarkTreeNodes[0].children[1].children;
    gotit = false
    for n in morebms
     if n.title is "conmarks" then gotit = true; return n
    if gotit is false then chrome.bookmarks.create {parentId:"2", title:"conmarks"}
###