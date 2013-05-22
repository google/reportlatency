
/**
 * @fileoverview This file contains QUnit tests for the TabStats object.
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

test('TabStats.add', function() {
  var s = new TabStats();

  s.add(1, 'name', 'navigation', 5);
  equal(s.stat[1].stat['name'].stat['navigation'].count, 1, 'single count');
  equal(s.stat[1].stat['name'].stat['navigation'].total, 5, 'single total');

  s.add(1, 'name', 'navigation', 9);
  equal(s.stat[1].stat['name'].stat['navigation'].count, 2, 'second count');
  equal(s.stat[1].stat['name'].stat['navigation'].total, 5 + 9, 'second total');
});
