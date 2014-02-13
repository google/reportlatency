
/**
 * @fileoverview This file contains QUnit tests for a TabData object.
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

  equal(t.stat.count('nreq'), 1, 'endRequest left 1 recorded requests');
  equal(t.stat.total('nreq'), 10, 'endRequest left 10 ms of requests');

  var dataStart2 = { requestId:2, timeStamp:1020,
		    url: 'http://host.example.com/image.png' };
  t.startRequest(dataStart2);
  var dataEnd2 = { requestId:2, timeStamp:1021, fromCache:true,
		  url: 'http://host.example.com/image.png' };
  t.endRequest(dataEnd2);

  equal(t.stat.count('nreq'), 1,
	'cached endRequest left 1 recorded requests');
  equal(t.stat.total('nreq'), 10,
	'cached endRequest left 10 ms of requests');

  // sometimes events in redirects are out of order and have sloppy timestamps.
  // It's not really clear what the right answer is, choose one that's
  // practical to implement.

  var dataStart3 = { requestId:3, timeStamp:1030,
		     url: 'http://host.example.com/v1' };
  t.startRequest(dataStart3);
  var dataStart4 = { requestId:3, timeStamp:1040, fromCache:false,
		     statusCode:304,
		     url: 'http://host.example.com/v2' };
  t.startRequest(dataStart4);

  var dataEnd3 = { requestId:3, timeStamp:1039, fromCache:false,
		   statusCode:304,
		   url: 'http://host.example.com/v1' };
  t.endRequest(dataEnd3);
  var dataEnd4 = { requestId:3, timeStamp:1054, fromCache:false,
		   statusCode:200,
		   url: 'http://host.example.com/v2' };
  t.endRequest(dataEnd4);

  equal(t.stat.count('nreq'), 3,
	'redirected endRequest left 3 recorded requests');

  // Want 33, but accepting 34 for now as well.
  var reqt = t.stat.total('nreq');
  ok(reqt >=  10 + 9 + 14 && reqt <= 34,
	'redirected endRequest left 33-34 ms of requests');


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

  equal(t.stat.count('nav'), 1, 'endNavigation left 1 count');
  equal(t.stat.total('nav'), 20, 'endNavigation 20 ms total');
  equal(t.service, '.', "TabData.service == '.'");
});

