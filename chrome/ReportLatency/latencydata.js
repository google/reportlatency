
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
}


/**
 * Records a start of a web request.
 *
 * @param {object} data is the callback data for Chrome's onBeforeRequest()
 *
 */
LatencyData.prototype.startRequest = function(data) {
  if ('tabId' in data) {
    if (!(data.tabId in this.tab)) {
      this.tab[data.tabId] = new TabData();
    }
    this.tab[data.tabId].startRequest(data);
  } else {
    console.log('malformed data in startRequest - no tabId');
  }
};

/**
 * Records end of a web request.
 *
 * @param {object} data is the callback data for Chrome's onCompletedRequest()
 *
 */
LatencyData.prototype.endRequest = function(data) {
  if ('tabId' in data) {
    if (data.tabId in this.tab) {
      this.tab[data.tabId].endRequest(data);
    } else {
      console.log(data.tabId + ' tabId not found in endRequest');
    }
  } else {
    console.log('malformed data in endRequest - no tabId');
  }
};

/**
 * Records end of a web request.
 *
 * @param {object} data is the callback data for Chrome's onErrorRequest()
 *
 */
LatencyData.prototype.deleteRequest = function(data) {
  if ('tabId' in data) {
    if (data.tabId in this.tab) {
      this.tab[data.tabId].deleteRequest(data);
    } else {
      console.log(data.tabId + ' tabId not found in deleteRequest');
    }
  } else {
    console.log('malformed data in deleteRequest - no tabId');
  }
};

/**
 * Forward starts and completions of tabupdates to the appropriate
 * TabData object.
 *
 * @param {object} data is the callback data for Chrome's onBeforeRequest()
 *
 */
LatencyData.prototype.tabUpdated = function(tabId, changeInfo, tab) {
  if (!(tabId in this.tab)) {
    this.tab[tabId] = new TabData();
  }
  this.tab[tabId].tabUpdated(changeInfo, tab);
}

/**
 * Delete the appropriate TabData object when tab is removed.
 *
 * @param {number} tabId is the callback data for Chrome's onRemoved()
 * @param {object} removeInfo is the callback data for Chrome's onRemoved()
 *
 */
LatencyData.prototype.tabRemoved = function(tabId, removeInfo) {
  if (tabId in this.tab) {
    delete this.tab[tabId];
  } else {
    console.log('delete for missing tabId ' + tabId + 
		' received in tabRemoved()');
  }
}

/**
 * Records a start of a navigation.
 *
 * @param {object} data is the callback data for Chrome's onBeforeRequest()
 *
 */
LatencyData.prototype.startNavigation = function(data) {
  if ('tabId' in data) {
    if (!(data.tabId in this.tab)) {
      this.tab[data.tabId] = new TabData();
    }
    this.tab[data.tabId].startNavigation(data);
  } else {
    console.log('malformed data in startNavigation - no tabId');
  }
};

/**
 * Records end of a navigation.
 *
 * @param {object} data is the callback data for Chrome's onCompletedRequest()
 *
 */
LatencyData.prototype.endNavigation = function(data) {
  if ('tabId' in data) {
    if (data.tabId in this.tab) {
      this.tab[data.tabId].endNavigation(data);
    } else {
      console.log(data.tabId + ' tabId not found in endNavigation');
    }
  } else {
    console.log('malformed data in endNavigation - no tabId');
  }
};

/**
 * Records end of a web navigation..
 *
 * @param {object} data is the callback data for Chrome's onErrorOccurred()
 *
 */
LatencyData.prototype.deleteNavigation = function(data) {
  if ('tabId' in data) {
    if (data.tabId in this.tab) {
      this.tab[data.tabId].deleteNavigation(data);
    } else {
      console.log(data.tabId + ' tabId not found in deleteNavigation()');
    }
  } else {
    console.log('malformed data in deleteNavigation() - no tabId');
  }
};

