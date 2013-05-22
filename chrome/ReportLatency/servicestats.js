
/**
 * @fileoverview ServiceStats is a container for all named services' stats
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
function ServiceStats() {
  this.stat = {};
}


/**
 * Adds a new measurement
 *
 * @param {string} service is the final name this stat is for
 * @param {string} name is the original request name this stat is for
 * @param {string} latency is the type of latency.
 * @param {number} delta is the new measurement to incorporate in the stat.
 *
 */
ServiceStats.prototype.add = function(service, name, latency, delta) {
  if (!this.stat[service]) {
    this.stat[service] = new NameStats();
  }
  this.stat[service].add(name, latency,  delta);
};


/**
 * Combine two measurements, zeroing one and transfering all counts to this
 *
 * @param {string} name is the service name to transfer tabId.
 * @param {number} tabId is the tab ID number to transfer into this.
 * @param {Object} tabStats is the source TabStats object.
 */
ServiceStats.prototype.transfer = function(name, tabId, tabStats) {
  if (name in this.stat) {
    this.stat[name].transfer(tabStats.stat[tabId]);
  } else {
    this.stat[name] = tabStats.stat[tabId];
  }
  tabStats.delete(tabId);
};


/**
 * @param {string} service is the service name to obtain stats of.
 */
ServiceStats.prototype.service = function(service) {
  return this.stat[service];
};

/**
 * @param {string} last service name in use
 * @returns {string} name of service with most navitations that isn't busy
 */
ServiceStats.prototype.best = function(last) {
  var navigations = 0;
  var requests = 0;
  var b;
  for (var s in this.stat) {
    if (s != last) {
      var nc = this.stat[s].count('navigation');
      if (nc > navigations) {
	navigations = nc;
	requests = this.stat[s].count('request');
	b = s;
      } else if (nc == navigations) {
	var nr = this.stat[s].count('request');
	if (nr > requests) {
	  requests = nr;
	  b = s;
	}
      }
    }
  }

  return b;
};


/**
 *
 * Delete a latency record for a named original and final service name
 *
 * @param {string} final name of service (as delivered)
 * @param {string} original name of service (as requested)
 */
ServiceStats.prototype.delete = function(final, original) {
  this.stat[final].delete(original);
  if (this.stat[final].empty()) {
    delete this.stat[final];
  }
}
