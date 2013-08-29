
function processHistory (filter) {
    this.filter = filter;

    this.loadHistory = function() {
        var date, daydate, endtime, microsecondsPerDay, mode, starttime, time;

        time = filter.time;
        mode = filter.mode;
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
            (historyItems.reverse()).forEach(function(site) {
                processed++;
                return chrome.history.getVisits({
                    url: site.url
                }, function(visitItems) {
                    return processVisitItems(site, visitItems);
                });
            });
            return null;
        });
    };

    processVisitItems = function(site, visitItems) {
        var SiteItem, bookmark, i, id, noblockreferred, ref, referrer, referringSiteId, relevance, time, type, vid, _i, _len;

        id = site.id;
        vid = visitItems[visitItems.length - 1].visitId;
        type = visitItems[visitItems.length - 1].transition;
        time = visitItems[visitItems.length - 1].visitTime;
        ref = visitItems[visitItems.length - 1].referringVisitId;
        relevance = visitItems.length;
        console.log(type + " " + id + " " + ref);

        info = $("<p>");
        info.text(  type + " " + id + " " + ref);
        br = $("<br>");
        $("#historycontent").append($(info));
        $("#historycontent").append($(br));
        /*----------------------------------------------------------------------------------------
         */

        referrer = [];
        noblockreferred = true;
        referringSiteId = "";
        for (_i = 0, _len = visitItems.length; _i < _len; _i++) {
            i = visitItems[_i];
            if (tabconnections[i.visitId] != null) {
                ref = tabconnections[i.visitId];
                referrer.push(tabconnections[i.visitId]);
            }
            if (visitId_pointo_SiteId[ref] != null) {
                noblockreferred = false;
                referringSiteId = visitId_pointo_SiteId[ref];
            }
            visitId_pointo_SiteId[i.visitId] = id;
            if (i.referringVisitId !== "0") {
                referrer.push(i.referringVisitId);
            }
        }
        /*----------------------------------------------------------------------------------------
         */

        if (type === "typed" || noblockreferred) {
            blocks[id] = blockId;
            blockId++;
            if (referrer.length > 0) {
                null;
            }
        } else {
            blocks[id] = blocks[referringSiteId];
        }
        SiteItem = {
            sid: site.id,
            vid: vid,
            url: site.url,
            title: site.title,
            type: type,
            ref: ref,
            relevance: relevance,
            block: blockId,
            sidref: referringSiteId,
            time: time
        };
        bookmark = bookMarks[site.url] != null ? null : void 0;
        siteHistory[id] = SiteItem;
        processed--;
        if (processed === 0) {
            return bookmartise();
        }
    };

}
