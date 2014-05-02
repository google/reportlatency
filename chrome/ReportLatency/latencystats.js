
/**
 * @fileoverview LatencyStats is a container of multiple types of
 *    latencies, each stored in a Stat object.
 * @author dld@google.com (DrakeDiedrich)
 *
 * Copyright 2013,2014 Google Inc. All Rights Reserved.
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
function LatencyStats() {
  this.stat = {};
}


/**
 * Adds a new measurement
 *
 * @param {string} latency is the type of latency.
 * @param {number} delta is the new measurement to incorporate in the stat.
 *
 * Stats are further grouped by original and final service, but this
 * isn't always known until after collection, so not part of this object.
 */
LatencyStats.prototype.add = function(latency, delta) {
  console.log('LatencyStats.add(' + latency + ',' + delta + ')');
  if (!this.stat[latency]) {
    this.stat[latency] = new Stat();
  }
  this.stat[latency].add(delta);
};

/**
 * Increments a countable event
 *
 * @param {string} latency is the type of latency event.
 * @param {string} result is the type of result instead of a latency
 *
 * Stats are further grouped by original and final service, but this
 * isn't always known until after collection, so not part of this object.
 */
LatencyStats.prototype.increment = function(latency, result) {
  if (!this.stat[latency]) {
    this.stat[latency] = new Stat();
  }
  this.stat[latency].increment(result);
};


/**
 * Combine two measurements, zeroing one and transfering all counts to this
 *
 * @param {Object} stats is another LatencyStats to transfer into this.
 */
LatencyStats.prototype.transfer = function(stats) {
  console.log('LatencyStats.transfer()');
  for (var s in stats.stat) {
    console.log('    s=' + s);
    if (this.stat[s]) {
      this.stat[s].transfer(stats.stat[s]);
    } else {
      this.stat[s] = stats.stat[s];
    }
    delete stats.stat[s];
  }
};


/**
 * @param {string} measurement is the name to aggregate.
 * @returns {number} the count and other countable fields for the
 *    requested measurement Stat
 */
LatencyStats.prototype.count = function(measurement) {
  var count=0;
  if (measurement in this.stat) {
    count += this.stat[measurement].count;
    for (var countable in this.stat[measurement]) {
      if (!(countable in Stat.prototype)) {
	if (countable != 'count' && countable != 'total' &&
	    countable != 'high' && countable != 'low') {
	  count += this.stat[measurement][countable];
	}
      }
    }
  }
  return count;
};

/**
 * @param {string} measurement is the name to aggregate.
 * @param {string} result is the result to aggregate.
 * @returns {number} the count field for the requested measurement Stat
 */
LatencyStats.prototype.countable = function(measurement,result) {
  if (measurement in this.stat) {
    if (result in this.stat[measurement]) {
      return this.stat[measurement][result];
    }
  }
  return 0;
};

/**
 * @param {string} measurement is the name to aggregate.
 * @returns {number} the total for the requested measurement Stat
 */
LatencyStats.prototype.total = function(measurement) {
  if (measurement in this.stat) {
    return this.stat[measurement].total;
  }
  return 0;
};

/**
 *
 * All the reportable data is in this.stat, so just report that for the
 * wire protocol
 *
 */
LatencyStats.prototype.toJSON = function() {
  return this.stat;
}
