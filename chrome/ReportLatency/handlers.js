
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

function onBeforeNavigate(data) {
  var d = new Date();
  latencyData.startNavigation(data);
}
chrome.webNavigation.onBeforeNavigate.addListener(onBeforeNavigate);

function onCompletedNavigation(data) {
  latencyData.endNavigation(data);
}
chrome.webNavigation.onCompleted.addListener(onCompletedNavigation);

function onNavigationError(data) {
  logObject('onNavigationError()', data);
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
  // console.log('onBeforeRequest(' + data.requestId + ',' + data.url + ')');
  latencyData.startRequest(data);
}
chrome.webRequest.onBeforeRequest.addListener( onBeforeRequest,
					       { urls: ['*://*/*'] });

function onBeforeRedirect(data) {
  // console.log('onBeforeRedirect(' + data.requestId  + ')');
  latencyData.endRequest(data);
}
chrome.webRequest.onBeforeRedirect.addListener( onBeforeRedirect,
						{ urls: ['*://*/*'] });


function onCompletedRequest(data) {
  // console.log('onCompletedRequest(' + data.requestId + ')');
  latencyData.endRequest(data);
}
chrome.webRequest.onCompleted.addListener( onCompletedRequest,
					   { urls: ['*://*/*'] });

function onRequestError(data) {
  logObject('onRequestError()', data);
  latencyData.deleteRequest(data);
}
chrome.webRequest.onErrorOccurred.addListener( onRequestError,
					       { urls: ['*://*/*'] });

function onStartup() {
  console.log('onStartup()');
}
chrome.runtime.onStartup.addListener( onStartup );

function onInstalled(details) {
  logObject('onInstalled()', details);
}
chrome.runtime.onInstalled.addListener( onInstalled );

function onSuspend() {
  console.log('onSuspend()');
}
chrome.runtime.onSuspend.addListener( onSuspend );

function onUpdateAvailable(details) {
  logObject('onUpdateAvailable()', details);
}
chrome.runtime.onInstalled.addListener( onUpdateAvailable );

function onMessage(message, sender, sendResponse) {
  if (sender.tab) {
    logObject(sender.tab.url + ' sent ' + message, message);
  } else {
    logObject('extension sent ' + message, sender);
  }
  var response;
  if (message.rpc == 'get_options') {
    response={serviceGroup: serviceGroup};
  }
  console.log('  response=' + JSON.stringify(response));
  sendResponse({serviceGroup: serviceGroup});
}
chrome.extension.onMessage.addListener(onMessage);
