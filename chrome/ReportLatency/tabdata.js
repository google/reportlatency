
/**
 * @fileoverview TabData is a container for all temporary stats by tabId,
 *   until the final service name is known and they are transfered to
 *   a ServiceStats object.
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
 * Class containing of multiple types of latencies
 * @constructor
 */
function TabData() {
  this.stat = new NameStats();
  this.request = {};
  this.tabupdate = {};
  this.navigation = {};
}

/**
 * Adds a new measurement
 *
 * @param {object} data about the request from Chrome onBeforeRequest().
 *
 */
TabData.prototype.beforeRequest = function(data) {
  if ('requestId' in data) {
    this.request[data.requestId] = data;
  } else {
    console.log('missing requestId in beforeRequest() data');
  }
};

/**
 * Adds a new measurement
 *
 * @param {object} data about the request from Chrome onCompletedRequest().
 *
 */
TabData.prototype.completedRequest = function(data) {
  if ('requestId' in data) {
    if (data.requestId in this.request) {
      if ('url' in data) {
	var name = aggregateName(data.url);
	if (name) {
	  var delay = data.timestamp - this.request[data.requestId].timestamp;
	  this.stat.add(name, 'request', delay);
	  delete this.request[data.requestId];
	} else {
	  console.log('no service name from ' + data.url +
		      ' in completedRequest()');
	}
      } else {
	console.log('missing data.url in completedRequest()');
      }
    } else {
      console.log('requestId ' + data.requestId + ' not found');
    }
  } else {
    console.log('missing requestId in completedRequest() data');
  }
};


/**
 * Adds a new measurement
 *
 * @param {number} tabId is the Id number of the tab to record this stat for
 * @param {string} name is the original request name this stat is for
 * @param {string} latency is the type of latency.
 * @param {number} delta is the new measurement to incorporate in the stat.
 *
 */
TabData.prototype.add = function(tabId, name, latency, delta) {
  if (!this.stat[tabId]) {
    this.stat[tabId] = new NameStats();
  }
  this.stat[tabId].add(name, latency,  delta);
};

/**
 * Delete all records for a tabId
 *
 * @param {number} tabId is the Id number of the tab.
 *
 */
TabData.prototype.delete = function(tabId) {
  delete this.stat[tabId];
};

/**
 *
 * @param {number} tabId is the Id number of the tab.
 * @returns {Object} then NameStats for tabId.
 *
 */
TabData.prototype.nameStats = function(tabId) {
  return this.stat[tabId];
};

