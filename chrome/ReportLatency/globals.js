
/**
 * @fileoverview globals.js has the initialization for the global statistics
 *   structures used by the Chrome extension, its unit tests, and the options
 *   configuration page.
 * @author dld@google.com (Drake Diedrich)
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

'use strict';

var optionDefault = {};
optionDefault['report_to'] = 'http://localhost/reportlatency/post';

// service_group{id}{'name'}
//            {'description'}
//            {'function'}
var serviceGroup = {};

// navigation{tabId}{frameId}{'url'}
// 'start', 'parent', 'children', ...
var navigation = {};

//  request{reqId}{'start'}
//    'url', 'redirect'
var request = {};

// tabupdate[tabId] = data
// store when tab is placed in status 'loading'
// report when tab is placed in status 'complete'
var tabupdate = {};

// LatencyStats by final and original servicename
// requests only populated once final service name is known
// serviceStats{final_service}{original_service} = LatencyStats;
var serviceStats = {};

// LatencyStats by tabID and current request URL
// requestStats{tabId}{URL_servicename} = LatencyStats
var requestStats = {};

// LatencyStats by tabID and current request URL
// tabStats{tabId}{URL_servicename} = LatencyStats
var tabStats = {};

var lastPostLatency = 0;
var postLatencyCheckCalls = 0;
