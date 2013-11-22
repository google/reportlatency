
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



/**
 * debugLog() is a console.log wrapper that the browser can enable.
 *
 * @param {string} str is the string to put in the Javascript console.
 **/
function debugLog(str) {
  if (localStorage['debug_mode'] == 'true') {
    console.log(str);
  }
}

/**
 * debugLogObject() is a console.log wrapper that the browser can enable.
 *
 * @param {string} str is the string to put in the Javascript console.
 * @param {object} o is an object to write to the Javascript console.
 **/
function debugLogObject(str, o) {
  if (localStorage['debug_mode'] == 'true') {
    logObject(str, o);
  }
}

/**
 * logObject() write object fields as strings to a function (typically
 * Javascript's console).
 *
 * @param {string} str is the string to put in the Javascript console.
 * @param {object} o is an object to write to the Javascript console.
 **/
function logObject(str, o) {
  console.log(str);
  for (var b in o) {
    console.log('  ' + b + ':' + o[b]);
  }
}

/**
 * registerService() registers a set of services with the extension.
 * This allows enterprise-specific registrations that are not part of
 * the open codebase.
 *
 * @param {string} id the unique name of the service being registered.
 * @param {string} description is the service description for the options page.
 * @param {function} callback is the URL-claiming function for the service.
 **/
function registerService(id, description, callback) {
  debugLog('registerService(' + id + ',' +
           description + ',' + callback + ')');

  var o = { 'description': description,
            'callback': callback };
  serviceGroup[id] = o;

  localStorage[id] = true;
}

/**
 * Return a list of the enabled wire protocol options.
 **/
function get_wire_options() {
  console.log('get_wire_options()  localStorage[]=' +
	      JSON.stringify(localStorage));
  var options = [];
  for (var id in serviceGroup) {
    console.log('    id=' + id);
    if (id in localStorage) {
      if (localStorage[id]) {
	console.log('      +');
	options.push(id);
      }
    }
  }
  if (localStorage['default_as_org']) {
    options.push('default_as_org');
  }
  console.log('  options=' + JSON.stringify(options));
  return options;
}

/**
 * @param {string} hostname is the full hostname.
 * @return {string} top two levels in a domain name.
 **/
function twoLevelDomain(hostname) {
  var patt = /[^.]+\.[^.]+$/i;
  var domain = patt.exec(hostname);
  if (domain) {
    return domain;
  } else {
    return hostname;
  }
}

/**
 * @param {string} hostname is the full hostname.
 * @return {string} the top three levels in a domain name.
 **/
function threeLevelDomain(hostname) {
  var patt = /[^.]+\.[^.]+\.[^.]+$/i;
  var domain = patt.exec(hostname);
  if (domain) {
    return domain;
  } else {
    return hostname;
  }
}


/**
 * @param {string} hostname is the full hostname.
 * @return {string} the top level in a domain name (TLD).
 **/
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

/**
 * @param {string} hostname is the full hostname.
 * @return {string} the top four levels in a domain name.
 **/
function fourLevelDomain(hostname) {
  var patt = /[^.]+\.[^.]+\.[^.]+\.[^.]+$/i;
  var domain = patt.exec(hostname);
  if (domain) {
    return domain;
  } else {
    return hostname;
  }
}

/**
 * fullHostname() is basically a no-op to put in table driven handlers.
 *
 * @param {string} hostname is the full hostname.
 * @return {string} the full hostname.
 **/
function fullHostname(hostname) {
  return hostname;
}

/**
 * @param {string} host is the full hostname.
 * @param {string} path is the rest of the URL.
 * @return {string} the full hostname and the first component of a URL.
 **/
var firstpathPatt = /^[^/?#]+/;
function hostFirstpath(host, path) {
  var service = firstpathPatt.exec(path);
  if (service) {
    return host + '/' + service;
  } else {
    return host;
  }
}


/**
 * @param {string} hostname is the full hostname.
 * @return {string} the 4, 3, or 2 LD for .us domains as appropriate.
 **/
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

/**
 * @param {string} hostname is the full hostname.
 * @return {string} the results of the appropriate TLD service name function.
 **/
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

/**
 * @param {string} url is the URL to test whether it is a http(s)?
 * @return {boolean} if url is a web URL.
 **/
var webUrlPatt = /^https?:/;
function isWebUrl(url) {
  if (webUrlPatt.exec(url)) {
    return true;
  }
  return false;
}

/**
 * aggregateName() calls all the registered service callbacks to see
 * if any will claim the URL.  If not, it may call the defaultDomain()
 * parser, else it returns '.' for "The Internet".
 *
 * @param {string} url is the URL to turn into a service name.
 * @return {string} is the service name to account traffic to.
 **/
function aggregateName(url) {
  var hostIndex = url.indexOf('://') + 3;
  var pathIndex = url.substr(hostIndex).indexOf('/');
  var host = url.substr(hostIndex, pathIndex);
  var path = url.substr(pathIndex + hostIndex + 1);

  for (var id in serviceGroup) {
    var cb = serviceGroup[id]['callback'];
    var name = cb(host, path);
    if (name) return name;
  }

  if (localStorage['default_as_org']) {
    return defaultDomain(host);
  }

  return '.';
}

/**
 * @return {string} the content of localStorage's report_to.
 **/
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

/**
 * timeZone() converts a Date() to a short name for the browser's timezone
 * as a proxy for office location.
 *
 * @param {string} date is a string as returned from Date().
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
