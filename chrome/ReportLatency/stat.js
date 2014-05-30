
/**
 * @fileoverview Stat holds enough composite data on a series of
 *     measurements to partially reconstruct the measurement distribution.
 *     Right now it holds just high, low, total and count, allowing
 *     average and range to be computed.
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
 * Class holding measurements that can reconstruct a range and average.
 * Also holds count of errors and interrupts for different events.
 * @constructor
 */
function Stat() {
  this.count = 0;
  this.total = 0;
}


/**
 * Adds a new measurement to a Stat (statistical measurement).
 * Limited data on the distribution is maintained, currently just
 * average, high, and low value.
 *
 * @param {number} delta The is a new measurement to incorporate in the stat.
 */
Stat.prototype.add = function(delta) {
  if (this.count == 1) {
    this.high = this.total;
  }

  if (this.count == 2) {
    this.low = this.total - this.high;
  }

  this.count++;
  this.total += delta;

  if (this.count>1) {
    if (delta > this.high) {
      this.high = delta;
    }
  }

  if (this.count>2) {
    if (delta < this.low) {
      this.low = delta;
    }
  }
};

Stat.prototype.increment = function(countable) {
  if (countable in this) {
    this[countable]++;
  } else {
    this[countable] = 1;
  }
}


/**
 * Combine two measurements, zeroing one and transfering all counts to this
 *
 * @this {Stat}
 * @param {Object} stat The stat to transfer into this and zero.
 */
Stat.prototype.transfer = function(stat) {
  if (stat.high) {
    if (this.high) {
      if (stat.high > this.high) {
        this.high = stat.high;
      }
    } else {
      this.high = stat.high;
    }
    delete stat['high'];
  }
  if (stat.low) {
    if (this.low) {
      if (stat.low < this.low) {
        this.low = stat.low;
      }
    } else {
      this.low = stat.low;
    }
    delete stat['low'];
  }
  for (var n in stat) {
    if (!(n in Stat.prototype)) {
      if (n in this) {
	this[n] += stat[n];
      } else {
	this[n] = stat[n];
      }
      delete stat[n];
    }
  }
};

