
/**
 * @fileoverview handlers.js holds the callback handlers
 *   for chrome.extensions events.  These are difficult to unit test, so
 *   only called from the production eventPage.js code.
 * @author dld@google.com (DrakeDiedrich)
 *
 * Copyright 2013 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */


/**
 * Post Latency summaries to central server.
 * Post just one summary at a time for interactivity.  Choose a good one.
 * The details object is used in this selection.

 * @param {Object} details has some recent state of the extension.
 **/
function postLatency(details) {
  debugLogObject('postLatency()', details);

  var bestFinal, bestOriginal;

  for (var final in serviceStats) {
    if (details.skip == final) {
      continue; // current service, wait
    }

    for (var original in serviceStats[final]) {
      if (details.skip == original) {
        continue; // current service, wait
      }

      // pick a good entry with navigations, if available
      if (bestFinal && bestOriginal) {
        if (serviceStats[final][original].navigation) {
          bestFinal = final;
          bestOriginal = original;
        }
      } else {
        bestFinal = final;
        bestOriginal = original;
      }
    }
  }

  if (bestFinal && bestOriginal) {
    var req = new XMLHttpRequest();
    var params = 'name=' + bestOriginal + '&final_name=' + bestFinal +
        '&tz=' + timeZone(Date());
    params += serviceStats[bestFinal][bestOriginal].params();

    console.log('  posting ' + params);
    req.open('POST', reportToUrl(), true);
    req.setRequestHeader('Content-type',
                         'application/x-www-form-urlencoded');
    req.send(params);
    delete serviceStats[bestFinal][bestOriginal];
    lastPostLatency = new Date().getTime();
    reportExtensionStats();
  }

}

/**
 * Call postLatency() to post a latency report if either enough time has
 * passed or many calls to this have already been made.  This reduces load
 * on the server and can be tuned as needed.

 * @param {string} skipname has a service name to skip over.
 **/
function postLatencyCheck(skipname) {
  var d = new Date();
  postLatencyCheckCalls++;
  if (d.getTime() - lastPostLatency > 10000 ||
      postLatencyCheckCalls > 10) {
    postLatencyCheckCalls = 0;
    postLatency({ 'skip': skipname });
  }
}

/**
 * tabUpdated() is a callback for when a Chrome tab has been updated.
 *
 * @param {number} tabId is the tab ID number in Chrome.
 * @param {object} changeInfo is an object with just the tab changes.
 * @param {object} tab is the full tab object available in Chrome.
 **/
function tabUpdated(tabId, changeInfo, tab) {
  if (!isWebUrl(tab.url)) { return; }
  var d = new Date();

  debugLog('tabUpdated(tabId:' + tabId + ') updated at ' +
      d.getTime() + ' (' + d + ')');
  debugLogObject('changeInfo', changeInfo);
  debugLogObject('tab', tab);

  if (tab.status == 'loading') {
    tabupdate[tabId] = {};
    tabupdate[tabId].changeInfo = changeInfo;
    tabupdate[tabId].start = d.getTime();
  } else if (tab.status == 'complete') {
    if (tabupdate[tabId]) {
      var delay = d.getTime() - tabupdate[tabId].start;
      debugLog('tab ' + tabId + ' (' + tab.url + ') updated in ' +
          delay + 'ms' + ' at ' + d.getTime());

      if (navigation[tabId]) {
        if (navigation[tabId]['0']) {
          if (navigation[tabId]['0']['final']) {
	    var final_name = navigation[tabId]['0']['final'];
	    if (!(final_name in serviceStats)) {
	      serviceStats[final_name] = new NameStats();
	    }
	    serviceStats[final_name].add(aggregateName(tab.url),
					 'tabupdate', delay);
          } else {
	    if (!(tabId in tabStats)) {
	      tabStats[tabId] = new NameStats();
	    }
            tabStats[tabId].add(aggregateName(tab.url),
				'tabupdate', delay);
          }
        }
        delete tabupdate[tabId];
      } else {
        debugLog('unexpected tabupdate received by tab ' + tabId +
            ' (' + tab.url + ')');
      }
    }
  }
}

/**
 * tabCreated() is a callback for when a Chrome tab has been created.
 *
 * @param {object} tab is the full tab object available in Chrome.
 **/
function tabCreated(tab) {
  if (!isWebUrl(tab.url)) { return; }
  var d = new Date();
  debugLog('tabCreated(tab:' + tab.id +
      ' url:' + tab.url + ') updated at ' +
      d.getTime() + ' (' + d + ')');
}


// webNavigation requests.  Might be true start of a request.
// regular page lifecycle

/**
 * onBeforeNavigate() is a callback for when a Navigation event starts.
 *
 * @param {object} data holds all information about the navigation request.
 **/
function onBeforeNavigate(data) {
  if (!isWebUrl(data.url)) {
    debugLog('onBeforeNavigate(' + data.url + ') not web');
    return;
  }

  var d = new Date();
  var s = 'onBeforeNavigate() fired at ' + d.getTime();
  debugLogObject(s, data);

  postLatencyCheck(aggregateName(data.url));

  // the parent isn't finished until all subframes complete,
  // so they have to be linked up at launch so the completed time
  // can be delayed

  if (!navigation[data.tabId]) {
    navigation[data.tabId] = {};
  }

  // TODO - make sure any data left is sent out before wipe

  // wipe out any pre-existing frame here - it's gone
  navigation[data.tabId][data.frameId] = {};

  navigation[data.tabId][data.frameId]['original'] =
      aggregateName(data.url);

  if (data.parentFrameId >= 0) {
    navigation[data.tabId][data.frameId]['parent'] =
        data.parentFrameId;
  }

  navigation[data.tabId][data.frameId]['start'] =
      data.timeStamp;


}

/**
 * onCompletedNavigation() is a callback for when a Navigation event completes.
 *
 * @param {object} data holds all information about the navigation event.
 **/
function onCompletedNavigation(data) {
  if (!isWebUrl(data.url)) {
    debugLog('onCompletedNavigation(' + data.url + ') not web');
    return;
  }

  var d = new Date();
  var s = 'onCompletedNavigation(' + data.url +
      ') in ' + delay + ' ms at ' + d.getTime();
  debugLogObject(s, data);


  if (navigation[data.tabId][data.frameId].hasOwnProperty('parent')) {
    // Meh.  Don't care about subframe navigation events.
  } else {
    // top level frame
    var delay = data.timeStamp -
        navigation[data.tabId][data.frameId]['start'];


    var final_name = aggregateName(data.url);
    navigation[data.tabId][data.frameId]['final'] = final_name;

    var original_name = navigation[data.tabId][data.frameId]['original'];
    serviceStats[final_name].add(original_name, 'navigation', delay);

    serviceStats[final_name].transfer(tabStats[data.tabId]);
    delete tabStats[data.tabId];
  }
}



/**
 * onErrorOccurred() is a callback for when a failed Navigation event.
 *
 * @param {object} data holds all information about the navigation event.
 **/
function onErrorOccurred(data) {
  var d = new Date();
  debugLogObject('onErrorOccurred() received at ' +
      d.getTime(), data);
}


/**
 * onReferenceFragmentUpdated() is a callback for when an in-page navigation.
 *
 * @param {object} data holds all information about the navigation event.
 **/
function onReferenceFragmentUpdated(data) {
  var d = new Date();
  debugLogObject('onReferenceFragmentUpdated(' + data.url +
      ') received at ' + d.getTime(), data);
}

/**
 * onTabReplaced() is a callback for a Chrome Tab that is replaced.
 *
 * @param {object} data holds all information about the tabupdate event.
 **/
function onTabReplaced(data) {
  var d = new Date();
  debugLogObject('onTabReplaced(' + data.url +
      ') received at ' + d.getTime(), data);
}


/**
 * onBeforeRequest() is a callback before every webRequest.
 *
 * @param {object} data holds all information about the request.
 **/
function onBeforeRequest(data) {
  debugLogObject('onBeforeRequest()', data);

  request[data.requestId] = data;
}


/**
 * onCompletedRequest() is a callback on completion of successful web requests.
 *
 * @param {object} data holds all information about the request.
 **/
function onCompletedRequest(data) {
  if (data.fromCache) {
    debugLog('onCompletedRequest(' + data.url + ') took ' +
        delay + 'ms at ' + data.timeStamp + ' fromCache');
    if (request[data.requestId]) {
      delete request[data.requestId];
    }
    return;
  }

  if (request[data.requestId]) {
    var delay = data.timeStamp - request[data.requestId].timeStamp;
    debugLogObject('onCompletedRequest() took ' +
        delay + 'ms at ' + data.timeStamp, data);

    if (navigation[data.tabId]) {
      if (navigation[data.tabId]['0']) {
        if (navigation[data.tabId]['0']['final']) {
          var final_name = navigation[data.tabId]['0']['final'];
	  serviceStats[final_name].add(aggregateName(data.url),
				       'request', delay);
        } else {
	  tabStats[data.tabId].add(aggregateName(data.url),
				   'request');
        }
      }
    } else {
      // arrived after webNavigationCompleted(), nowhere to log
      debugLog('  requestId ' + data.requestId + ' (' + data.url +
               ') not in request[]');
    }
    delete request[data.requestId];
  } else {
    debugLogObject('onCompletedRequest() start not recorded', data);
  }
}


/**
 * onErrorOccurredRequest() is a callback on failed web requests.
 *
 * @param {object} data holds all information about the request.
 **/
function onErrorOccurredRequest(data) {
  debugLogObject('onErrorOccurredRequest()', data);
  delete request[data.requestId];
}


chrome.tabs.onUpdated.addListener(tabUpdated);
chrome.tabs.onCreated.addListener(tabCreated);
chrome.webNavigation.onBeforeNavigate.addListener(onBeforeNavigate);
chrome.webNavigation.onCompleted.addListener(onCompletedNavigation);
//chrome.webNavigation.onErrorOccurred.addListener(onErrorOccurred);
chrome.webNavigation.onReferenceFragmentUpdated.addListener(
    onReferenceFragmentUpdated);
chrome.webNavigation.onTabReplaced.addListener(onTabReplaced);
chrome.webRequest.onBeforeRequest.addListener(
    onBeforeRequest, { urls: ['*://*/*'] });
chrome.webRequest.onBeforeRedirect.addListener(
    onCompletedRequest, { urls: ['*://*/*'] });
chrome.webRequest.onCompleted.addListener(
    onCompletedRequest, { urls: ['*://*/*'] });
chrome.webRequest.onErrorOccurred.addListener(
    onErrorOccurredRequest, { urls: ['*://*/*'] });
