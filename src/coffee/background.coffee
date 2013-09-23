lastPage = ""

tabConnections = {}


#chrome.storage.local.remove("tabConnections")

# bisherig gespeicherte Verbindungen laden  
chrome.storage.local.get "tabConnections", (result) ->
  if result.tabConnections? 
    tabConnections = result.tabConnections

    

# Tab Inhalt geladen? --> 
chrome.tabs.onUpdated.addListener (tabId, changeInfo, tab) ->
  if changeInfo.status is "complete"
    setTabConnection(tab.url, tab.openerTabId)


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
              chrome.storage.local.set "tabConnections":tabConnections




  
# Track Forward/Backward-Interaction
chrome.webNavigation.onCommitted.addListener (details) ->
  #if details.transitionType then console.log details.transitionType
  if details.transitionQualifiers
    if details.transitionQualifiers is "forward_back"
       lastPage = details.url

###
chrome.history.onVisited.addListener (details) ->
  console.log details
###
