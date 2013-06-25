
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
  this.tab = {};
  this.stats = new ServiceStats();
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
  debugLogObject('LatencyData.tabRemoved(' + tabId + ',removeInfo)',
		 removeInfo);
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
 * @param {object} data is the callback data for Chrome's onBeforeNavigate()
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
 * Handles tasks postponed until service name was known.
 *
 * @param {object} data is the callback data for onCompletedNavigation()
 *
 */
LatencyData.prototype.endNavigation = function(data) {
  if ('tabId' in data) {
    if (data.tabId in this.tab) {
      this.tab[data.tabId].endNavigation(data);
      if ('service' in this.tab[data.tabId]) {
	var service = this.tab[data.tabId].service;
	this.stats.transfer(service, this.tab[data.tabId].stat);
	this.postLatency(service);
      }
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

/**
 * Post Latency summaries to central server.
 * Post just one summary at a time for interactivity.  Choose a good one.
 * The details object is used in this selection.

 * @param {string} skip is a servicename to skip reports for
 **/
LatencyData.prototype.postLatency = function(skip) {
  debugLog('postLatency(! ' + skip + ')');

  var bestFinal = this.stats.best(skip);
  if (!bestFinal) {
    return;
  }
  debugLog("bestFinal = " + bestFinal);
  var bestService = this.stats.service(bestFinal);
  var bestOriginal = bestService.best(skip);

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
    this.stats.delete(bestFinal,bestOriginal);
    this.reportExtensionStats();
  }

}

/**
 * reportExtensionStats() writes some stats about the pending and
 * completed events the extension has seen to the console.
 *
 **/
LatencyData.prototype.reportExtensionStats = function() {
  console.log('ReportLatency');
  var services = '';
  for (var n in this.stats.stat) {
    services = services.concat(' ' + n );
  }
  /*
  console.log('  ' + Object.keys(navigation).length +
              ' outstanding navigations');
  console.log('  ' + Object.keys(request).length +
              ' outstanding requests');
  console.log('  ' + Object.keys(tabupdate).length +
              ' outstanding tabupdates');
  */
  console.log('  ' + Object.keys(this.stats.stat).length +
              ' pending service reports:' + services);
}
