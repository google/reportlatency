
/**
 * @fileoverview This file contains QUnit tests for the NameStats object.
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

test('NameStats.add', function() {
  var s = new NameStats();

  s.add('name', 'navigation', 5);
  equal(s.stat['name'].stat['navigation'].count, 1, 'single count');
  equal(s.stat['name'].stat['navigation'].total, 5, 'single total');

  s.add('name', 'navigation', 9);
  equal(s.stat['name'].stat['navigation'].count, 2, 'second count');
  equal(s.stat['name'].stat['navigation'].total, 5 + 9, 'second total');
});

test('NameStats.increment', function() {
  var s = new NameStats();
  s.increment('name', 'navigation', 'error');
  equal(s.stat['name'].stat['navigation'].error, 1, 'single error');
});

test('NameStats.transfer', function() {
  var s = new NameStats();
  var t = new NameStats();

  s.add('server1','navigation', 5);
  s.add('server1', 'request', 3);
  s.add('server2', 'request', 50);
  t.add('server1', 'request', 4);
  t.add('server1', 'tabupdate', 1);
  t.add('server2', 'request', 30);
  t.transfer(s);
  equal(s.stat['server1'], undefined, 'zeroed server1');
  equal(s.stat['server2'], undefined, 'zeroed server2');
  equal(t.stat['server1'].stat['navigation'].total, 5,
	'server1 navigation total');
  equal(t.stat['server1'].stat['navigation'].count, 1,
	'server1 navigation count');
  equal(t.stat['server1'].stat['request'].total, 3+4, 'server1 request total');
  equal(t.stat['server1'].stat['request'].count, 2, 'server1 request count');
  equal(t.stat['server1'].stat['tabupdate'].total, 1,
	'server1 tabudpate total');
  equal(t.stat['server1'].stat['tabupdate'].count, 1,
	'server1 tabupdate count');
  equal(t.stat['server2'].stat['request'].total, 30+50,
	'server1 request total');
  equal(t.stat['server2'].stat['request'].count, 2,
	'server2 request count');
});

test('NameStats.count', function() {
  var s = new NameStats();

  s.add('server', 'navigation', 5);
  s.add('server', 'navigation', 9);
  s.add('redirector', 'navigation', 9);
  equal(s.count('navigation'), 6, '6 navigations added');
  equal(s.total('navigation'), 5+9+9, 'total()');
});

