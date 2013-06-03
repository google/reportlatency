
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


var latencyData = new LatencyData();

/**
 * Post Latency summaries to central server.
 * Post just one summary at a time for interactivity.  Choose a good one.
 * The details object is used in this selection.

 * @param {Object} details has some recent state of the extension.
 **/
function postLatency(details) {
  debugLogObject('postLatency()', details);

  var bestFinal = serviceStats.best(details.skip);
  if (!bestFinal) {
    return;
  }
  console.log("bestFinal = " + bestFinal);
  var bestService = serviceStats.service(bestFinal);
  var bestOriginal = bestService.best(details.skip);

  if (bestFinal && bestOriginal) {
    var req = new XMLHttpRequest();
    var params = 'name=' + bestOriginal + '&final_name=' + bestFinal +
        '&tz=' + timeZone(Date());
    params += bestService.stat[bestOriginal].params();

    console.log('  posting ' + params);
    req.open('POST', reportToUrl(), true);
    req.setRequestHeader('Content-type',
                         'application/x-www-form-urlencoded');
    req.send(params);
    serviceStats.delete(bestFinal,bestOriginal);
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



function onBeforeNavigate(data) {
  latencyData.startNavigation(data);
}
chrome.webNavigation.onBeforeNavigate.addListener(onBeforeNavigate);

function onCompletedNavigation(data) {
  latencyData.endNavigation(data);
}
chrome.webNavigation.onCompleted.addListener(onCompletedNavigation);

function onNavigationError(data) {
  latencyData.deleteNavigation(data);
}
chrome.webNavigation.onErrorOccurred.addListener(onNavigationError);



function onTabUpdated(tabId, changeInfo, tab) {
  latencyData.tabUpdated(tabId, changeInfo, tab);
}
chrome.tabs.onUpdated.addListener(onTabUpdated);

function onTabRemoved(tabId, removeInfo) {
  latencyData.tabRemoved(tabId, removeInfo);
}
chrome.tabs.onRemoved.addListener(onTabRemoved);


function onBeforeRequest(data) {
  latencyData.startRequest(data);
}
chrome.webRequest.onBeforeRequest.addListener( onBeforeRequest,
					       { urls: ['*://*/*'] });
chrome.webRequest.onBeforeRedirect.addListener( onBeforeRequest,
						{ urls: ['*://*/*'] });


function onCompletedRequest(data) {
  latencyData.endRequest(data);
}
chrome.webRequest.onCompleted.addListener( onCompletedRequest,
					   { urls: ['*://*/*'] });

function onRequestError(data) {
  latencyData.deleteRequest(data);
}
chrome.webRequest.onErrorOccurred.addListener( onRequestError,
					       { urls: ['*://*/*'] });
