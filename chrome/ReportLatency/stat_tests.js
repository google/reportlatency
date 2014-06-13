
/**
 * @fileoverview This file contains QUnit tests for the Stat object.
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

test('Stat.add', function() {
  var s = new Stat();
  equal(s.count, 0, 'empty count');
  equal(s.total, 0, 'empty total');
  equal(s.high, undefined, 'empty high');
  equal(s.low, undefined, 'empty low');

  s.add(550);
  equal(s.count, 1, 'single count');
  equal(s.total, 550, 'single total');
  equal(s.high, undefined, 'single high');
  equal(s.low, undefined, 'empty low');

  s.add(30);
  equal(s.count, 2, 'double count');
  equal(s.total, 580, 'double total');
  equal(s.high, 550, 'double high');
  equal(s.low, undefined, 'triple low');

  s.add(1500);
  equal(s.count, 3, 'triple count');
  equal(s.total, 2080, 'triple total');
  equal(s.high, 1500, 'triple high');
  equal(s.low, 30, 'triple low');

  equal(s.m10000, undefined, 'no 10s bin yet');

  s.add(300);
  s.add(330);
  s.add(360);
  s.add(3000);
  s.add(5000);
  s.add(6000);
  s.add(59000);

  equal(s.m100, 1, '1 100ms bin');
  equal(s.m500, 3, '3 500ms bin');
  equal(s.m1000, 1, '1 1s bin');
  equal(s.m2000, 1, '1 2s bin');
  equal(s.m4000, 1, '1 4s bin');
  equal(s.m10000, 2, '2 10s bin');
});

test('Stat.increment', function() {
  var s = new Stat();
  equal(s.error, undefined, 'empty error');

  s.increment('error');
  equal(s.error, 1, 'single error');

  s.increment('error');
  equal(s.error, 2, 'double error');
});

test('Stat.transfer', function() {
  var s = new Stat();
  var t = new Stat();

  t.count = 1;
  t.total = 10;
  t.high = 10;
  t.error = 1;

  s.transfer(t);

  equal(t.count, undefined, 'empty tmp count');
  equal(t.total, undefined, 'empty tmp total');
  equal(t.high, undefined, 'empty tmp high');
  equal(t.error, undefined, 'empty tmp error');

  equal(s.count, 1, 'first transfer count');
  equal(s.total, 10, 'first transfer total');
  equal(s.high, 10, 'first transfer high');
  equal(s.error, 1, 'first transfer error');


  t.count = 3;
  t.total = 24;
  t.high = 12;
  t.error = 1;
  s.interrupt = 1;

  s.transfer(t);

  equal(t.count, undefined, 'empty tmp count');
  equal(t.total, undefined, 'empty tmp total');
  equal(t.high, undefined, 'empty tmp high');
  equal(t.error, undefined, 'empty tmp error');
  equal(t.interrupt, undefined, 'empty tmp interrupt');

  equal(s.count, 4, 'second transfer count');
  equal(s.total, 34, 'second transfer total');
  equal(s.high, 12, 'second transfer high');
  equal(s.error, 2, 'second transfer error');
  equal(s.interrupt, 1, 'second transfer interrupt');

  t.count = 1;
  t.total = 2;
  t.high = 2;

  s.transfer(t);

  equal(s.count, 5, 'third transfer count');
  equal(s.total, 36, 'third transfer total');
  equal(s.high, 12, 'third transfer high');
  equal(s.error, 2, 'third transfer error');
  equal(s.interrupt, 1, 'third transfer interrupt');
});

