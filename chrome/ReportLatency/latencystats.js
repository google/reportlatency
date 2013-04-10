
/**
 * @fileoverview LatencyStats is a container of multiple types of
 *    latencies, each stored in a Stat object.
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
  if (!this.stat[latency]) {
    this.stat[latency] = new Stat();
  }
  this.stat[latency].add(delta);
};

/**
 * Combine two measurements, zeroing one and transfering all counts to this
 *
 * @param {Object} stats is another LatencyStats to transfer into this.
 */
LatencyStats.prototype.transfer = function(stats) {
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
 * Return a CGI form string used in reporting a Stat centrally.
 *
 * @param {string} name The name of this stat as reported to the server.
 * @return {string} CGI form string representing this Stat.
 */
LatencyStats.prototype.params = function(name) {
  var params = '';
  for (var s in this.stat) {
    params = params + this.stat[s].params(s);
  }
  return params;
};
