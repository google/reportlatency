
/**
 * @fileoverview fucntions.js holds the testable, non-member functions
 *   called by handlers.js and the various *_service.js service name
 *   generating code.
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


// Registered services storage, shared within extension
localStorage['services'] = JSON.stringify({});


function debugLog(str) {
  if (localStorage['debug_mode'] == 'true') {
    console.log(str);
  }
}

function debugLogObject(str, o) {
  if (localStorage['debug_mode'] == 'true') {
    console.log(str);
    for (var b in o) {
      console.log('  ' + b + ':' + o[b]);
    }
  }
}

function registerService(id, description, callback) {
  debugLog('registerService(' + id + ',' +
           description + ',' + callback + ')');

  var o = { 'description': description,
            'callback': callback };
  serviceGroup[id] = o;

  var services = JSON.parse(localStorage['services']);
  services[id] = true;
  localStorage['services'] = JSON.stringify(services);
  localStorage[id] = true;
  localStorage[id + '_description'] = description;
}

function twoLevelDomain(hostname) {
  var patt = /[^.]+\.[^.]+$/i;
  var domain = patt.exec(hostname);
  if (domain) {
    return domain;
  } else {
    return hostname;
  }
}

function threeLevelDomain(hostname) {
  var patt = /[^.]+\.[^.]+\.[^.]+$/i;
  var domain = patt.exec(hostname);
  if (domain) {
    return domain;
  } else {
    return hostname;
  }
}

function reportExtensionStats() {
  console.log('ReportLatency');
  var services = '';
  for (var n in serviceStats) {
    var c = Object.keys(serviceStats[n]).length;
    if (c == 0) {
      delete serviceStats[n];
    } else {
      services = services.concat(' ' + n + '(' +
                                 Object.keys(serviceStats[n]).length + ')');
    }
  }
  console.log('  ' + Object.keys(navigation).length +
              ' outstanding navigations');
  console.log('  ' + Object.keys(request).length +
              ' outstanding requests');
  console.log('  ' + Object.keys(tabupdate).length +
              ' outstanding tabupdates');
  console.log('  ' + Object.keys(serviceStats).length +
              ' pending service reports:' + services);
}


function topLevelDomain(hostname) {
  var patt = /\./;
  var dot = patt.exec(hostname);
  if (dot) {
    var patt = /[^.]+$/i;
    var tld = patt.exec(hostname);
    if (tld) {
      return tld[0];
    }
  }
  return null;
}

function fourLevelDomain(hostname) {
  var patt = /[^.]+\.[^.]+\.[^.]+\.[^.]+$/i;
  var domain = patt.exec(hostname);
  if (domain) {
    return domain;
  } else {
    return hostname;
  }
}

function fullHostname(hostname) {
  return hostname;
}

var firstpathPatt = /^[^/?#]+/;
function hostFirstpath(host, path) {
  var service = firstpathPatt.exec(path);
  if (service) {
    return host + '/' + service;
  } else {
    return host;
  }
}


var usLocalityPatt = /(co|ci|town|vil)\.[^.]+\.[^.]{2}\.us$/;
var usStatePatt = /state\.[^.]{2}\.us$/;
function usDomain(hostname) {
  if (usLocalityPatt.exec(hostname)) {
    return fourLevelDomain(hostname);
  }

  if (usStatePatt.exec(hostname)) {
    return threeLevelDomain(hostname);
  }

  return twoLevelDomain(hostname);
}

var tldMap = {
  'us': usDomain
};

function defaultDomain(hostname) {
  var tld = topLevelDomain(hostname);

  if (tld) {
    var foo = tldMap[tld];
    if (foo) {
      var name = foo(hostname);
      if (name) return name;
    }

    if (tld.length == 2) return threeLevelDomain(hostname);

    // Most 2 and 4+ letter TLDs are two levels deep to get to orgs
    return twoLevelDomain(hostname);
  }

  // unqualified hostname returned
  return hostname;
}

var webUrlPatt = /^https?:/;
function isWebUrl(url) {
  if (webUrlPatt.exec(url)) {
    return true;
  }
  return false;
}

// aggregate URLs into service names we'll report stats against
function aggregateName(url) {
  var hostIndex = url.indexOf('://') + 3;
  var pathIndex = url.substr(hostIndex).indexOf('/');
  var host = url.substr(hostIndex, pathIndex);
  var path = url.substr(pathIndex + hostIndex + 1);

  var services = JSON.parse(localStorage['services']);
  for (var id in services) {
    var cb = serviceGroup[id]['callback'];
    var name = cb(host, path);
    if (name) return name;
  }

  if (localStorage['default_as'] == 'domain') {
    return defaultDomain(host);
  }

  return '.';
}

function reportToUrl() {
  if ('report_to' in localStorage) {
    var r = localStorage['report_to'];
    if ((r != null) && (r != '')) {
      return r;
    } else {
      delete localStorage['report_to'];
    }
  }
  return optionDefault['report_to'];
}

// reduced wrapper used for per-originalname/finalname LatencyStats.
// Eventually will become another shallow wrapper and disappear around
// a larger object.
function updateStats(finalName, originalName,
                     fieldName, delta, stats) {
  debugLog('updateStats(' + finalName + ',' + originalName + ',' +
           fieldName + ',' + delta + ',' + stats + ')');
  if (!(finalName in stats)) {
    stats[finalName] = {};
  }
  var sf = stats[finalName];
  if (!(originalName in sf)) {
    stats[finalName][originalName] = new LatencyStats();
  }

  stats[finalName][originalName].add(fieldName, delta);
}

// reduced wrapper used for per-originalname LatencyStats.  Eventually
// will become another shallow wrapper and disappear around a larger object.
function transferStats(tmpStats, serviceStats) {
  if (tmpStats && serviceStats) {
    for (var s in tmpStats) {
      if (serviceStats[s]) {
        debugLog('transferStats(' + s + ') accumlate');
        serviceStats[s].transfer(tmpStats[s]);
      } else {
        debugLog('transferStats(' + s + ') copy');
        serviceStats[s] = tmpStats[s];
      }
      delete tmpStats[s];
    }
  }
}

/**
 * timeZone() converts a Date() to a short name for the browser's timezone
 * as a proxy for office location.
 *
 * @param {string} date is a string as returned from Date().
 *
 * @return {string} the timezone abbreviation or offset.  Returns null
 *   if not recognized as a date.
 **/

function timeZone(date) {
  var abbrev = date.match(/GMT(\+|\-)\d{4} \(([A-Z]{3,5})\)/)[2];
  if (abbrev) { return abbrev; }

  var offset = date.match(/GMT(\+|\-)\d{4}/);
  if (offset) { return offset; }

  return null;
}
