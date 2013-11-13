
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
  latencyData.startNavigation(data);
}
chrome.webNavigation.onBeforeNavigate.addListener(onBeforeNavigate);

function onCompletedNavigation(data) {
  latencyData.endNavigation(data);
}
chrome.webNavigation.onCompleted.addListener(onCompletedNavigation);

function onNavigationError(data) {
  console.log('onNavigationError(' + data + ')');
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
  console.log('onRequestError(' + data + ')');
  latencyData.deleteRequest(data);
}
chrome.webRequest.onErrorOccurred.addListener( onRequestError,
					       { urls: ['*://*/*'] });

function onStartup() {
  console.log('onStartup()');
}
chrome.runtime.onStartup.addListener( onStartup );

function onInstalled(details) {
  console.log('onInstalled(' + details.reason + ',' +
	      details.perviousVersion + ')');
}
chrome.runtime.onInstalled.addListener( onInstalled );

function onSuspend() {
  console.log('onSuspend()');
}
chrome.runtime.onSuspend.addListener( onSuspend );

function onUpdateAvailable(details) {
  console.log('onUpdateAvailable(' + details.version + ')');
}
chrome.runtime.onInstalled.addListener( onUpdateAvailable );

