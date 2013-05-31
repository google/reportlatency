
/**
 * @fileoverview This file contains QUnit tests for the LatencyStats object.
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

test('LatencyStats.add', function() {
  var s = new LatencyStats();

  s.add('navigation', 5);
  equal(s.stat['navigation'].count, 1, 'single count');
  equal(s.stat['navigation'].total, 5, 'single total');

  s.add('navigation', 9);
  equal(s.stat['navigation'].count, 2, 'second count');
  equal(s.stat['navigation'].total, 5 + 9, 'second total');
});

test('LatencyStats.transfer', function() {
  var s = new LatencyStats();
  var t = new LatencyStats();

  s.add('navigation', 5);
  s.add('request', 3);
  t.add('request', 4);
  t.add('tabupdate', 1);
  t.transfer(s);
  equal(s.stat['navigation'], undefined, 'zeroed navigation');
  equal(s.stat['request'], undefined, 'zeroed request');
  equal(t.stat['navigation'].total, 5, 'navigation total');
  equal(t.stat['navigation'].count, 1, 'navigation count');
  equal(t.stat['request'].total, 7, 'request total');
  equal(t.stat['request'].count, 2, 'request count');
  equal(t.stat['tabupdate'].total, 1, 'tabupdate total');
  equal(t.stat['tabupdate'].count, 1, 'tabupdate count');
});

test('LatencyStats.params', function() {
  var s = new LatencyStats();

  s.add('navigation', 5);
  equal(s.params(),
      '&navigation_count=1&navigation_total=5' +
      '&navigation_high=5&navigation_low=5',
      'values');
});

test('LatencyStats.count', function() {
  var s = new LatencyStats();

  s.add('navigation', 5);
  s.add('navigation', 10);
  s.add('request', 2);
  equal(s.count('navigation'), 2, '2 navigations added');
  equal(s.count('request'), 1, '1 request added');
  equal(s.count('tabupdates'), 0, '0 tabupdates');
});

