
/**
 * @fileoverview This file contains QUnit tests for the Stat object.
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

test('Stat.add', function() {
  var s = new Stat();
  equal(s.count, 0, 'empty count');
  equal(s.total, 0, 'empty total');
  equal(s.high, undefined, 'empty high');

  s.add(5);
  equal(s.count, 1, 'single count');
  equal(s.total, 5, 'single total');
  equal(s.high, 5, 'single high');

  s.add(3);
  equal(s.count, 2, 'double count');
  equal(s.total, 8, 'double total');
  equal(s.high, 5, 'double high');

  s.add(10);
  equal(s.count, 3, 'triple count');
  equal(s.total, 18, 'triple total');
  equal(s.high, 10, 'triple high');

});

test('Stat.transfer', function() {
  var s = new Stat();
  var t = new Stat();

  t.count = 1;
  t.total = 10;
  t.high = 10;

  s.transfer(t);

  equal(t.count, undefined, 'empty tmp count');
  equal(t.total, undefined, 'empty tmp total');
  equal(t.high, undefined, 'empty tmp high');

  equal(s.count, 1, 'first transfer count');
  equal(s.total, 10, 'first transfer total');
  equal(s.high, 10, 'first transfer high');

  t.count = 3;
  t.total = 24;
  t.high = 12;

  s.transfer(t);

  equal(t.count, undefined, 'empty tmp count');
  equal(t.total, undefined, 'empty tmp total');
  equal(t.high, undefined, 'empty tmp high');

  equal(s.count, 4, 'second transfer count');
  equal(s.total, 34, 'second transfer total');
  equal(s.high, 12, 'second transfer high');

  t.count = 1;
  t.total = 2;
  t.high = 2;

  s.transfer(t);

  equal(s.count, 5, 'third transfer count');
  equal(s.total, 36, 'third transfer total');
  equal(s.high, 12, 'third transfer high');
});

test('Stat.params', function() {
  var s = new Stat();
  equal(s.params('f'), '', 'empty');

  s.add(1);
  equal(s.params('f'),
      '&f_count=1&f_total=1&f_high=1&f_low=1',
      'values');
});

