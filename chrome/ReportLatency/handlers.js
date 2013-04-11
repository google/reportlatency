
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


// post Latency summaries to central server
// post just one summary at a time for interactivity
function postLatency(details) {
  debugLogObject('postLatency()', details);

  var best_final, best_original, best_navigations, best_requests;

  for (var final in serviceStats) {
    if (details.skip == final) {
      continue; // current service, wait
    }

    for (var original in serviceStats[final]) {
      if (details.skip == original) {
        continue; // current service, wait
      }

      // pick a good entry with navigations, if available
      if (best_final && best_original) {
        if (serviceStats[final][original].navigation) {
          best_final = final;
          best_original = original;
        }
      } else {
        best_final = final;
        best_original = original;
      }
    }
  }

  if (best_final && best_original) {
    var req = new XMLHttpRequest();
    var params = 'name=' + best_original + '&final_name=' + best_final +
        '&tz=' + timeZone(Date());
    params += serviceStats[best_final][best_original].params();

    console.log('  posting ' + params);
    req.open('POST', reportToUrl(), true);
    req.setRequestHeader('Content-type',
                         'application/x-www-form-urlencoded');
    req.send(params);
    delete serviceStats[best_final][best_original];
    last_post_latency = new Date().getTime();
    reportExtensionStats();
  }

}

// postLatency() if enough data is collected or time has passed
// can skip the name of the currently-being-processed service
function postLatencyCheck(skipname) {
  var d = new Date();
  post_latency_check_calls++;
  if (d.getTime() - last_post_latency > 10000 ||
      post_latency_check_calls > 10) {
    post_latency_check_calls = 0;
    postLatency({ 'skip': skipname });
  }
}


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
            updateStats(navigation[tabId]['0']['final'],
                        aggregateName(tab.url),
                        'tabupdate', delay, serviceStats);
            transferStats(tabStats[tabId],
                          serviceStats[navigation[tabId]['0']['final']]);
          } else {
            updateStats(tabId, aggregateName(tab.url),
                        'tabupdate', delay, tabStats);
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

function tabCreated(tab) {
  if (!isWebUrl(tab.url)) { return; }
  var d = new Date();
  debugLog('tabCreated(tab:' + tab.id +
      ' url:' + tab.url + ') updated at ' +
      d.getTime() + ' (' + d + ')');
}


// webNavigation requests.  Might be true start of a request.
// regular page lifecycle

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

    updateStats(final_name,
                navigation[data.tabId][data.frameId]['original'],
                'navigation', delay, serviceStats);

    transferStats(requestStats[data.tabId],
                  serviceStats[final_name]);
    delete requestStats[data.tabId];

    transferStats(tabStats[data.tabId],
                  serviceStats[final_name]);
    delete tabStats[data.tabId];
  }
}



// Exceptions to regular page lifecycle

function onErrorOccurred(data) {
  var d = new Date();
  debugLogObject('onErrorOccurred() received at ' +
      d.getTime(), data);
}


function onReferenceFragmentUpdated(data) {
  var d = new Date();
  debugLogObject('onReferenceFragmentUpdated(' + data.url +
      ') received at ' + d.getTime(), data);
}

function onTabReplaced(data) {
  var d = new Date();
  debugLogObject('onTabReplaced(' + data.url +
      ') received at ' + d.getTime(), data);
}


//
// webRequest events
//

function onBeforeRequest(data) {
  debugLogObject('onBeforeRequest()', data);

  request[data.requestId] = data;
}


function onCompletedRequest(data) {
  if (data.fromCache) {
    debugLog('onCompletedRequest(' + data.url + ') took ' +
        delay + 'ms at ' + data.timeStamp + ' fromCache');
    return;
  }

  if (request[data.requestId]) {
    var delay = data.timeStamp - request[data.requestId].timeStamp;
    debugLogObject('onCompletedRequest() took ' +
        delay + 'ms at ' + data.timeStamp, data);

    if (navigation[data.tabId]) {
      if (navigation[data.tabId]['0']) {
        if (navigation[data.tabId]['0']['final']) {
          updateStats(navigation[data.tabId]['0']['final'],
                      aggregateName(data.url),
                      'request', delay, serviceStats);
          transferStats(requestStats[data.tabId],
                        serviceStats[navigation[data.tabId]['0']['final']]);
        } else {
          updateStats(data.tabId, aggregateName(data.url),
                      'request', delay, requestStats);
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
