
/**
 * @fileoverview LatencyData is the top level data object for ReportLatency.
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
 * Class containing all data for ReportLatency
 * @constructor
 */
function LatencyData() {
  console.log('new LatencyData()');
  this.tab = {}
  this.service = {};
}


/**
 * Records a new beginning of a web request.
 *
 * @param {object} data is the callback data for Chrome's onBeforeRequest()
 *
 */
LatencyData.prototype.beforeRequest = function(data) {
  if ('tabId' in data) {
    if (!(data.tabId in this.tab)) {
      this.tab[data.tabId] = new TabData();
    }
    this.tab[data.tabId].beforeRequest(data);
  } else {
    console.log('malformed data in beforeRequest - no tabId');
  }
};

/**
 * Records end of a web request.
 *
 * @param {object} data is the callback data for Chrome's onBeforeRequest()
 *
 */
LatencyData.prototype.completedRequest = function(data) {
  if ('tabId' in data) {
    if (data.tabId in this.tab) {
      this.tab[data.tabId].completedRequest(data);
    } else {
      console.log(data.tabId + ' tabId not found in completedRequest');
    }
  } else {
    console.log('malformed data in beforeRequest - no tabId');
  }
};
