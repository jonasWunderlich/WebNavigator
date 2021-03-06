// Generated by CoffeeScript 1.6.2
(function() {
  var blockSum, block_counter, block_set, blocks, filterArray, idToRef, lastTitle, lastUrl, lastVid, loadHistory, logInfo, processHistoryItems, processVisitItems, processed, siteHistory, tabconnections, urltoblock, visitIdAufSID;

  processed = 0;

  tabconnections = [];

  lastVid = 0;

  lastUrl = "";

  siteHistory = [];

  visitIdAufSID = [];

  idToRef = {};

  urltoblock = {};

  block_counter = 0;

  block_set = 0;

  blockSum = 0;

  blocks = [];

  lastTitle = "";

  filterArray = ["adf.ly"];

  loadHistory = function(callbackFn) {
    processed = 0;
    tabconnections = [];
    lastVid = 0;
    lastUrl = "";
    siteHistory = [];
    visitIdAufSID = [];
    idToRef = {};
    urltoblock = {};
    block_counter = 0;
    block_set = 0;
    blockSum = 0;
    blocks = [];
    return chrome.storage.local.get("tabConnections", function(result) {
      if (result.tabConnections) {
        tabconnections = result.tabConnections;
      } else {
        tabconnections = [];
      }
      return processHistoryItems(callbackFn);
    });
  };

  processHistoryItems = function(callbackFn) {
    var date, daydate, endtime, microsecondsPerDay, starttime, time;

    time = filter.time;
    processed = 0;
    date = new Date();
    daydate = date.getTime() - ((((date.getHours() + 1) * 60 + date.getMinutes()) * 60 + date.getSeconds()) * 1000);
    microsecondsPerDay = 1000 * 60 * 60 * 24;
    endtime = daydate - (microsecondsPerDay * (time - 1));
    starttime = daydate - (microsecondsPerDay * (30 + time));
    return chrome.history.search({
      text: filter.query,
      startTime: starttime,
      endTime: endtime,
      maxResults: filter.results
    }, function(historyItems) {
      return (historyItems.reverse()).forEach(function(site) {
        processed++;
        return chrome.history.getVisits({
          url: site.url
        }, function(visitItems) {
          return processVisitItems(site, visitItems, callbackFn);
        });
      });
    });
  };

  processVisitItems = function(site, visitItems, callbackFn) {
    var bookmark, context, count, i, id, ref, referrer, siteItem, tab, testurl, time, type, url, vid, vids, _i, _len;

    referrer = vids = [];
    id = site.id;
    url = site.url;
    if (/data:/.test(url)) {
      null;
    } else {
      vid = visitItems[visitItems.length - 1].visitId;
      ref = visitItems[visitItems.length - 1].referringVisitId;
      type = visitItems[visitItems.length - 1].transition;
      time = visitItems[visitItems.length - 1].visitTime;
      count = site.visitCount;
      for (_i = 0, _len = visitItems.length; _i < _len; _i++) {
        i = visitItems[_i];
        if (i.visitId > vid - 300) {
          if (tabconnections[i.visitId] != null) {
            referrer.push(tabconnections[+i.visitId]);
          }
          if (i.referringVisitId !== "0") {
            referrer.push(i.referringVisitId);
          }
          visitIdAufSID[i.visitId] = id;
        }
      }
      idToRef[id] = referrer;
      testurl = url.split("//")[1];
      url = testurl.substr(0, 10);
      if ((type === "link" || type === "form_submit") && (lastVid === ref || lastUrl === url)) {
        urltoblock[url] = block_set;
      } else {
        if ((urltoblock[url] != null) && url !== "www.google" && url !== "www.youtub") {
          block_set = urltoblock[url];
        } else {
          block_counter++;
          blocks[block_counter] = {
            "id": block_counter,
            "context": "",
            "time": "",
            "processed": false,
            "google": false
          };
          if (/google/.test(url)) {
            blocks[block_counter].google = true;
          }
          block_set = block_counter;
          urltoblock[url] = block_set;
        }
      }
      lastVid = vid;
      lastUrl = url;
      context = "";
      bookmark = void 0;
      if (bookMarks[site.url] != null) {
        context = bookMarks[site.url].context;
        bookmark = bookMarks[site.url].bid;
        blocks[block_set].context = context;
      }
      blocks[block_set].time = time;
      tab = tabArray[site.url] != null ? tabArray[site.url] : "";
      if (site.title === "" || (lastTitle !== site.title && !(jQuery.inArray(url.substr(0, 6), filterArray) >= 0))) {
        siteItem = {
          sid: id,
          vid: vid,
          url: site.url,
          title: site.title,
          type: type,
          ref: ref,
          relevance: count,
          time: time,
          block: block_set,
          context: context,
          tab: tab,
          bid: bookmark
        };
        siteHistory[id] = siteItem;
      } else {
        null;
      }
      lastTitle = site.title;
    }
    processed--;
    if (processed === 0) {
      blockSum = block_counter;
      return callbackFn();
    }
  };

  logInfo = function(infoarray) {
    var i, info, k, siteinfo;

    siteinfo = $("<div>");
    for (k in infoarray) {
      i = infoarray[k];
      info = $("<div>");
      info.text(i);
      info.addClass("infotext");
      if (k === "0") {
        info.addClass("title");
      }
      siteinfo.append($(info));
    }
    return $("#historycontent").append($(siteinfo));
  };

  /*
  createBlocks = () ->
    block = 1
    for id,val of siteHistory
      processed++
      for v in idToRef[id]
        processed++
        if visitIdAufSID[v]?
          if siteHistory[visitIdAufSID[v]].block != 0 #block wird geerbt
            if val.block != 0
              for s in siteHistory # noch berücksichtigen dass andere mitgenommen werden
                if s.block == val.block then s.block = siteHistory[visitIdAufSID[v]].block
            val.block = siteHistory[visitIdAufSID[v]].block
          else
            if val.block == 0
              siteHistory[visitIdAufSID[v]].block = val.block = block #gibt nix zu erben man braucht einen neuen
              block++
            else
              siteHistory[visitIdAufSID[v]].block = val.block #gibt nix & man hat schon -> in die andere richtung vererben
        processed--
      if val.block is 0 or idToRef[id].length is 0
        val.block = block
        block++
      processed--
    if processed is 0
      for k,i of siteHistory
        logInfo([i.title.substr(0,40), i.sid, i.vid, i.ref, i.type, i.block])
  */


}).call(this);
