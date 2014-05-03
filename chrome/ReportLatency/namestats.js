
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
 * Adds a new countable event result
 *
 * @param {string} name is the original request name this stat is for
 * @param {string} latency is the type of latency.
 * @param {number} countable is event result rather than a latency delay
 *
 */
NameStats.prototype.increment = function(name, latency, countable) {
  if (!this.stat[name]) {
    this.stat[name] = new LatencyStats();
  }
  this.stat[name].increment(latency, countable);
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
 *
 * @param {string} measurement type of latency.
 * @param {string} result name for latency type.
 * @returns {number} the total number of events returning the result.
 */
NameStats.prototype.countable = function(measurement, result) {
  var c = 0;
  for (var s in this.stat) {
    c += this.stat[s].countable(measurement, result);
  }
  return c;
};

/**
 *
 * @param {string} measurement to aggregate.
 * @returns {number} the total of measurement reports.
 */
NameStats.prototype.total = function(measurement) {
  var c = 0;
  for (var s in this.stat) {
    c += this.stat[s].total(measurement);
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
 * @param {string} last name of data set collected, and to skip over.
 * @returns {string} name of best data set to report.
 */
NameStats.prototype.best = function(last) {
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
 * All the reportable data is in this.stat, so just report that for the
 * wire protocol
 *
 */
NameStats.prototype.toJSON = function() {
  return this.stat;
}
