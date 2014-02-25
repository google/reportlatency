
/**

 * @fileoverview This file contains QUnit tests for the LatencyData
 * object - the top data object used in ReportLatency.
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

test('LatencyData.*Request', function() {
  var ld = new LatencyData();
  var ts = ld.tab[1] = new TabData();

  var data = {
    url: 'http://server/path',
    tabId: 1,
    requestId: 20,
    timeStamp: 1000
  };

  ld.startRequest(data);

  data.timeStamp = 2000;
  ld.endRequest(data);

  var ts = ld.tab[1].stat;
  equal(ts.count('nreq'), 1, '1 request for tab 1');
});

test('LatencyData.*Navigation', function() {
  var ld = new LatencyData();
  var data = { frameId:0, parentFrameId:-1, processId:2999, tabId:30,
	       timeStamp:1000, url:'http://host/' };

  ld.startNavigation(data);

  data.timeStamp = 2000;
  ld.endNavigation(data);
  var ts = ld.tab[30].stat;

  ld.tabRemoved(30, {});

  equal(ts.count('nav'), 1, '1 navigation for tab 30');
  equal(ts.countable('nav','tabclosed'), 0,
		     '0 tabclosed events for tab 30');
  equal(ld.countable('nav','tabclosed'), 0,
	'0 global tabclosed events');

  data.timeStamp = 3000;
  data.url = 'http://host/spinsforever';
  ld.startNavigation(data);
  ts = ld.tab[30].stat;
  equal(ts.count('nav'), 0, '0 navigation for tab 30');
  ld.tabRemoved(30, {});
  equal(ld.countable('nav','tabclosed'), 1,
	'1 tabclosed events');
});

test('LatencyData.Navigation_Request', function() {
  var ld = new LatencyData();
  var navdata = { frameId:0, parentFrameId:-1, processId:2999, tabId:30,
	          timeStamp:1000, url:'http://host/' };

  ld.startNavigation(navdata);

  var reqdata = {
    url: 'http://host/path',
    tabId: 30,
    requestId: 20,
    timeStamp: 2010
  };
  ld.startRequest(reqdata);

  reqdata.timeStamp = 2310;
  ld.endRequest(reqdata);

  navdata.timeStamp = 2000;
  ld.endNavigation(navdata);

  var ts = ld.tab[30].stat;
  equal(ts.count('nreq'), 1, '1 navigation request for tab 30');
  equal(ts.count('ureq'), 0, '0 update request for tab 30');
});

