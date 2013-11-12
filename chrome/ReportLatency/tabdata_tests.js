
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

  var data = { requestId:1, timeStamp:1000, url: 'http://host.example.com/' };
  t.startRequest(data);
  data.timeStamp = 1001;
  t.deleteRequest(data);

  equal(t.stat.count('request'), 0, 'deleteRequest left 0 recorded requests');
});

test('TabData.endRequest', function() {
  var t = new TabData();

  var dataStart = { requestId:1, timeStamp:1000,
		    url: 'http://host.example.com/' };
  t.startRequest(dataStart);
  var dataEnd = { requestId:1, timeStamp:1010, fromCache:false,
		  url: 'http://host.example.com/' };
  t.endRequest(dataEnd);

  equal(t.stat.count('request'), 1, 'endRequest left 1 recorded requests');
  equal(t.stat.total('request'), 10, 'endRequest left 10 ms of requests');

  var dataStart2 = { requestId:2, timeStamp:1020,
		    url: 'http://host.example.com/image.png' };
  t.startRequest(dataStart2);
  var dataEnd2 = { requestId:2, timeStamp:1021, fromCache:true,
		  url: 'http://host.example.com/image.png' };
  t.endRequest(dataEnd2);

  equal(t.stat.count('request'), 1,
	'cached endRequest left 1 recorded requests');
  equal(t.stat.total('request'), 10,
	'cached endRequest left 10 ms of requests');
});

test('TabData.tabUpdated', function() {
  var t = new TabData();

  var tab = {
    status: 'loading',
    url: 'http://server/path',
    tabId: 1,
  };
  var changeInfo = {};
  t.tabUpdated(changeInfo, tab);
  tab.status = 'complete';
  t.tabUpdated(changeInfo, tab);

  equal(t.stat.count('tabupdate'), 1, 'tabUpdated left 1 recorded tabupdate');
});


test('TabData.startNavigation', function() {
  var t = new TabData();

  var data = { frameId:0, parentFrameId:-1, processId:2999, tabId:30,
	       timeStamp:1000, url:'http://host.example.com/' };
  t.startNavigation(data);

  equal(t.navigation.frameId, 0, 'frameId');
});

test('TabData.endNavigation', function() {
  var t = new TabData();

  var dataStart = { frameId:0, parentFrameId:-1, processId:2999, tabId:30,
	       timeStamp:1000, url:'http://host.example.com/' };
  t.startNavigation(dataStart);

  var dataEnd = { frameId:0, processId:2999, tabId:30,
	       timeStamp:1020, url:'http://host.example.com/' };
  t.endNavigation(dataEnd);

  equal(t.stat.count('navigation'), 1, 'endNavigation left 1 count');
  equal(t.stat.total('navigation'), 20, 'endNavigation 20 ms total');
  equal(t.service, '.', "TabData.service == '.'");
});

