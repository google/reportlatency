
/**
 * @fileoverview This file contains QUnit tests for the ServiceStats object.
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

test('ServiceStats.add', function() {
  var s = new ServiceStats();

  s.add('service', 'name', 'navigation', 5);
  equal(s.stat['service'].stat['name'].stat['navigation'].count,
	1, 'single count');
  equal(s.stat['service'].stat['name'].stat['navigation'].total,
	5, 'single total');
});

test('ServiceStats.transfer', function() {
  var s = new ServiceStats();
  var n = new NameStats();

  n.add('name', 'navigation', 3);
  s.transfer('service', n);
  equal(n.empty(), false, 'NameStats not empty');
  equal(s.stat['service'].stat['name'].stat['navigation'].count, 1,
	'1 navigations added');

  n.add('name', 'request', 2);
  equal(s.stat['service'].stat['name'].stat['request'].count, 1,
	'1 request passed through');

  n = new NameStats();
  n.add('name', 'navigation', 5);
  s.transfer('service', n);
  equal(n.empty(), true, 'NameStats now empty');
  equal(s.stat['service'].stat['name'].stat['navigation'].count, 2,
	'2 navigations added');
});

test('ServiceStats.best', function() {
  var s = new ServiceStats();

  s.add('service', 'server', 'navigation', 5);
  s.add('service', 'redirector', 'navigation', 10);
  s.add('content', 'server2', 'request', 1);
  s.add('current', 'server3', 'navigation', 1);
  s.add('current', 'server3', 'navigation', 2);
  s.add('current', 'server3', 'navigation', 3);

  equal(s.best('current'), 'service',
	'service that isn\'t in use with most navigations chosen');
});

test('ServiceStats.delete', function() {
  var s = new ServiceStats();

  s.add('service', 'server', 'navigation', 5);
  s.add('service', 'redirector', 'navigation', 10);
  
  s.delete('service','server');
  ok('service' in s.stat,'service still present');
  ok('redirector' in s.stat['service'].stat, 'redirector present');
  ok(! ('server' in s.stat['service'].stat), 'server deleted');

  s.delete('service', 'redirector');
  ok(!('service' in s.stat),'service deleted');
});

