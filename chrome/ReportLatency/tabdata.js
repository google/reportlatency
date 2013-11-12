
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
}

/**
 * Adds a new measurement
 *
 * @param {object} data about the request from Chrome onBeforeRequest().
 *
 */
TabData.prototype.startRequest = function(data) {
  debugLogObject('TabData.startRequest(data)', data);
  console.log('startRequest timeStamp:' + data.timeStamp);
  if ('requestId' in data) {
    if (data.requestId in this.request) {
      console.log('interleaved requestId ' + data.requestId);
      var data1 = Object.create(this.request[data.requestId]);
      data1.timeStamp = data.timeStamp;
      data1.statusCode = data.statusCode;
      this.endRequest(data1);
    }
    console.log('request[' + data.requestId + '] = ' + data);
    this.request[data.requestId] = data;
  } else {
    console.log('missing requestId in startRequest() data');
  }
};

/**
 * Adds a new measurement
 *
 * @param {object} data about the request from Chrome onCompletedRequest().
 *
 */
TabData.prototype.endRequest = function(data) {
  debugLogObject('TabData.endRequest(data)', data);
  console.log('endRequest timeStamp:' + data.timeStamp);
  if ('requestId' in data) {
    if (data.requestId in this.request) {
      console.log('  old timeStamp:' + this.request[data.requestId].timeStamp);
      if (!data.fromCache) {
	if (('url' in data) &&
	    (data.url == this.request[data.requestId].url)) {
	  var name = aggregateName(data.url);
	  if (name) {
	    var delay = data.timeStamp -
	      this.request[data.requestId].timeStamp;
	    console.log('adding ' + delay + ' ms to ' + name + ' request stats');
	    this.stat.add(name, 'request', delay);
	  } else {
	    console.log('no service name from ' + data.url +
			' in endRequest()');
	  }
	  delete this.request[data.requestId];
	} else {
	  console.log('missing or mismatched data.url in endRequest()');
	}
      }
    } else {
      console.log('requestId ' + data.requestId + ' not found in endRequest');
    }
  } else {
    console.log('missing requestId in endRequest() data');
  }
};

/**
 * Delete a request (due to an error).
 *
 * @param {object} data about the request from Chrome onErrorRequest().
 *
 */
TabData.prototype.deleteRequest = function(data) {
  debugLogObject('TabData.deleteRequest(data)', data);
  if ('requestId' in data) {
    if (data.requestId in this.request) {
      delete this.request[data.requestId];
    } else {
      console.log('requestId ' + data.requestId +
		  ' not found in deleteRequest()');
    }
  } else {
    console.log('missing requestId in deleteRequest() data');
  }
};

/**
 * Delete a request (due to an error).
 *
 * @param {object} data about the request from Chrome onErrorRequest().
 *
 */
TabData.prototype.tabUpdated = function(changeInfo, tab) {
  debugLogObject('TabData.tabUpdated(changeInfo)', changeInfo);
  debugLogObject('TabData.tabUpdated(tab)', tab);
  if (!isWebUrl(tab.url)) { return; }
  var d = new Date();

  if (tab.status == 'loading') {
    this.tabupdate = {};
    this.tabupdate.changeInfo = changeInfo;
    this.tabupdate.start = d.getTime();
  } else if (tab.status == 'complete') {
    if ('start' in this.tabupdate) {
      var delay = d.getTime() - this.tabupdate.start;
      debugLog('tab ' + tab.tabId + ' (' + tab.url + ') updated in ' +
          delay + 'ms' + ' at ' + d.getTime());
      var name = aggregateName(tab.url);
      this.stat.add(name, 'tabupdate', delay);
    }
  }
};


/**
 * startNavigation() is a callback for when a Navigation event starts.
 *
 * @param {object} data about the navigation from Chrome onBeforeNavigation().
 *
 */
TabData.prototype.startNavigation = function(data) {
  debugLogObject('TabData.startNavigation(data)', data);
  if (('parentFrameId' in data) && (data.parentFrameId < 0)) {
    if ('service' in this) {
      delete this['service'];
    }
    if ('url' in data) {
      if (isWebUrl(data.url)) {
	if ('timeStamp' in data) {
	  this.navigation = data;
	} else {
	  console.log('missing timeStamp in startNavigation() data');
	}
      } else {
	console.log('startNavigation(' + data.url + ') not web');
      }
    } else {
      console.log('no url found in endNavigation() data');
    }
  } else {
    // Meh.  Don't care about subframe navigation events.
  }
};

/**
 * endNavigation() is a callback for when a Navigation event completes.
 *
 * @param {object} data about the navigation from Chrome onCompletedNavigation().
 *
 */
TabData.prototype.endNavigation = function(data) {
  debugLogObject('TabData.endNavigation(data)', data);
  if ('navigation' in this) {
    if (('frameId' in data)) {
      if (data.frameId == this.navigation.frameId) {
	if ('url' in data) {
	  if (isWebUrl(data.url)) {
	    if ('timeStamp' in data) {
	      var delay = data.timeStamp - this.navigation.timeStamp;
	      var original_name = aggregateName(this.navigation.url);
	      this.service = aggregateName(data.url);
	      this.stat.add(original_name, 'navigation', delay);
	    } else {
	      console.log('missing timeStamp in endNavigation() data');
	    }
	  } else {
	    console.log('endNavigation(' + data.url + ') not web');
	  }
	} else {
	  console.log('no url found in endNavigation() data');
	}
      } else {
	// Meh. Don't care about subframes again
	// console.log('data.frameId ' + data.frameId + 
	//	    ' != this.navigation.frameId ' + this.navigation.frameId);
      }
    } else {
      console.log('no frameId found');
    }
  } else {
    console.log('no existing navigation');
  }
};

/**
 * endNavigation() is a callback for when a Navigation event completes.
 *
 * @param {object} data about the navigation from Chrome onCompletedNavigation().
 *
 */
TabData.prototype.deleteNavigation = function(data) {
  debugLogObject('TabData.deleteNavigation(data)', data);
  if ('navigation' in this) {
    delete this['navigation'];
  }
};
