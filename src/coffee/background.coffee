
lastPage = ""
#tabArray = []
tabConnections = {}

# bisherig gespeicherte Verbindungen laden  
chrome.storage.local.get "tabConnections", (result) ->
  if result.tabConnections? 
    tabConnections = result.tabConnections
    #console.log tabConnections
    

# Tab Inhalt geladen? --> 
chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  if changeInfo.status is "complete"
    #console.log tab
    setTabConnection(tab.url, tab.openerTabId)
    #tabArray[tab.id] = url:tab.url,index:tab.index,windowId:tab.windowId,openerTabId:tab.openerTabId,highlighted:tab.highlighted,active:tab.active,pinned:tab.pinned, title:tab.title,incognito:tab.incognito
    #syncTabs()
    

# Verbindung speichern falls Referenz auf fremdes Tab zeigt
# & Übersicht nicht involviert ist
setTabConnection = (newTabUrl, openerTabId) ->
  visit = 0
  if typeof(openerTabId) isnt "undefined"
    chrome.tabs.get openerTabId, (openertab) ->
      if openertab.url isnt "chrome://newtab/" and newTabUrl isnt "chrome://newtab/"
        chrome.history.getVisits {url:newTabUrl}, (visitItems) ->
          #console.log visitItems
          if visitItems.length > 0
            visit = visitItems[visitItems.length-1].visitId
            chrome.history.getVisits {url:openertab.url}, (visitItems) ->
              tabConnections[visit] = visitItems[visitItems.length-1].visitId
              #alttabConnections[visit] = visitItems[visitItems.length-1].id
              chrome.storage.local.set "tabConnections":tabConnections




  
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