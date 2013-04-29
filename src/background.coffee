#chrome.storage.local.remove("tabs")
#chrome.storage.local.remove("connections")
lastPage = ""
tabArray = []
connections = []
chrome.storage.local.get "connections", (result) ->
  if result.connections? then connections = result.connections



chrome.tabs.onCreated.addListener (tab) ->
  console.log tab
  #save NewTab in Array
  tabArray[tab.id] = url:tab.url,index:tab.index,windowId:tab.windowId,openerTabId:tab.openerTabId,highlighted:tab.highlighted,active:tab.active,pinned:tab.pinned, title:tab.title,incognito:tab.incognito
  syncTabs()
  #save Connection between newTab and Origin
  setTabConnection(tab.url,tab.openerTabId)
  
setTabConnection = (orgTabUrl,referrerTabId) ->
  if typeof(referrerTabId) isnt "undefined"
    chrome.tabs.get referrerTabId, (tab) ->
      if tab.url isnt "chrome://newtab/"
        connections.push url:orgTabUrl, refurl:tab.url, nav:"tab"
        #console.log connections
        syncConnectedTabs()
      lastPage = tab.url


# synchronise Storage of Tabinfo
syncTabs = ->
  chrome.storage.local.set "tabs":tabArray

# synchronise Storage of connected Tabs
syncConnectedTabs = ->
  chrome.storage.local.set "connections":connections
  
# Track Forward/Backward-Interaction
chrome.webNavigation.onCommitted.addListener (details) ->
  #console.log details
  #if details.transitionType then console.log details.transitionType
  if details.transitionQualifiers
    if details.transitionQualifiers is "forward_back"
       connections.push url:details.url, refurl:lastPage, nav:"forward_back"
       lastPage = details.url


### Query for getting all Tabs at once
chrome.tabs.query {}, (Tabs) ->
  console.log Tabs
###


#chrome.webNavigation.onBeforeNavigate.addListener (details) ->
  #console.log details