
/**
 * @fileoverview NameStats is a container of named LatencyStats objects
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
function NameStats() {
  this.stat = {};
}


/**
 * Adds a new measurement
 *
 * @param {string} name is the original request name this stat is for
 * @param {string} latency is the type of latency.
 * @param {number} delta is the new measurement to incorporate in the stat.
 *
 */
NameStats.prototype.add = function(name, latency, delta) {
  if (!this.stat[name]) {
    this.stat[name] = new LatencyStats();
  }
  this.stat[name].add(latency,  delta);
};


/**
 * Combine two measurements, zeroing one and transfering all counts to this
 *
 * @param {Object} stats is another NameStats to transfer into this.
 */
NameStats.prototype.transfer = function(stats) {
  for (var s in stats.stat) {
    if (this.stat[s]) {
      this.stat[s].transfer(stats.stat[s]);
    } else {
      this.stat[s] = stats.stat[s];
    }
    delete stats.stat[s];
  }
};

/**
 *
 * @param {string} measurement to aggregate.
 * @returns {number} the total number of measurement reports.
 */
NameStats.prototype.count = function(measurement) {
  var c = 0;
  for (var s in this.stat) {
    c += this.stat[s].count(measurement);
  }
  return c;
};


/**
 * @returns {boolean} true if this entire object is empty.
 */
NameStats.prototype.empty = function() {
  for (var s in this.stat) {
    return false;
  }
  return true;
};

/**
 * @param {string} name of the data set to delete.
 */
NameStats.prototype.delete = function(name) {
  delete this.stat[name];
};


