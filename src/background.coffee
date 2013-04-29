#chrome.storage.local.remove("tabs")
#chrome.storage.local.remove("connections")
lastPage = ""
#tabArray = []
connections = []

# bisherig gespeicherte Verbindungen laden  
chrome.storage.local.get "connections", (result) ->
  if result.connections? 
    connections = result.connections
    #console.log connections
    

# Tab Inhalt geladen? --> 
chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  if changeInfo.status is "complete"
    console.log tab
    setTabConnection(tab.url,tab.openerTabId)
    #tabArray[tab.id] = url:tab.url,index:tab.index,windowId:tab.windowId,openerTabId:tab.openerTabId,highlighted:tab.highlighted,active:tab.active,pinned:tab.pinned, title:tab.title,incognito:tab.incognito
    #syncTabs()
    

# Verbindung speichern falls Referenz auf fremdes Tab zeigt
# & Übersicht nicht involviert ist
setTabConnection = (orgTabUrl,referrerTabId) ->
  if typeof(referrerTabId) isnt "undefined"
    chrome.tabs.get referrerTabId, (tab) ->
      if tab.url isnt "chrome://newtab/" and orgTabUrl isnt "chrome://newtab/"
        connections.push url:orgTabUrl, refurl:tab.url, nav:"tab"
        chrome.storage.local.set "connections":connections
      lastPage = tab.url
      




  
# Track Forward/Backward-Interaction
chrome.webNavigation.onCommitted.addListener (details) ->
  #console.log details
  #if details.transitionType then console.log details.transitionType
  if details.transitionQualifiers
    if details.transitionQualifiers is "forward_back"
       #connections.push url:details.url, refurl:lastPage, nav:"forward_back"
       lastPage = details.url










### Query for getting all Tabs at once
chrome.tabs.query {}, (Tabs) ->
  console.log Tabs

# synchronise Storage of Tabinfo
syncTabs = ->
  chrome.storage.local.set "tabs":tabArray

chrome.webNavigation.onBeforeNavigate.addListener (details) ->
  console.log details
###