
/**
 * @fileoverview This file contains QUnit tests for a TabData object.
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

test('TabData.deleteRequest', function() {
  var t = new TabData();

  var data = { requestId:1, timestamp:1000, url: 'http://host/' };
  t.startRequest(data);
  data.timestamp = 1001;
  t.deleteRequest(data);

  equal(t.stat.count('request'), 0, 'deleteRequest left 0 recorded requests');
});

test('TabData.endRequest', function() {
  var t = new TabData();

  var data = { requestId:1, timestamp:1000, url: 'http://host/' };
  t.startRequest(data);
  data.timestamp = 1001;
  t.endRequest(data);

  equal(t.stat.count('request'), 1, 'endRequest left 1 recorded requests');
});
