
/**
 * @fileoverview google_services.js has functions that add on to the
 *    default URL-flattening function, and generate specific service names
 *    for Google services from their URL.
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

var google_two_ld_function_map = {
  'google.com': threeLevelDomain,
  'youtube.com': twoLevelDomain,
  'youtube-nocookie.com': twoLevelDomain,
  'youtu.be': twoLevelDomain,
  'ytimg.com': twoLevelDomain,
  'doubleclick.net': twoLevelDomain,
  'googlesyndication.com': twoLevelDomain,
  'admob.com': twoLevelDomain,
  'googletagservices.com': twoLevelDomain,
  'googleadservices.com': twoLevelDomain,
  'google-analytics.com': twoLevelDomain,
  'urchin.com': twoLevelDomain,
  'googletagmanager.com': twoLevelDomain,
  'gstatic.com': twoLevelDomain,
  'goo.gl': twoLevelDomain,
  'g.co': twoLevelDomain,
  'googlecommerce.com': twoLevelDomain,
  'android.com': twoLevelDomain,
  'googleapis.com': twoLevelDomain,
  'appspot.com': twoLevelDomain,
  'withgoogle.com': twoLevelDomain,
  'blogger.com': twoLevelDomain,
  'blogblog.com': twoLevelDomain,
  'blogspot.com': twoLevelDomain,
  'googlecode.com': twoLevelDomain,
  'googlesource.com': twoLevelDomain,
  'googlegroups.com': twoLevelDomain,
  'googleusercontent.com': twoLevelDomain,
  'ggpht.com': twoLevelDomain,
  'googledrive.com': twoLevelDomain,
  'gmail.com': twoLevelDomain,
  'googleitahosted.com': twoLevelDomain,
  'itasoftware.com': twoLevelDomain,
  'widevine.tv': twoLevelDomain,
  'widevine.com': twoLevelDomain,
  'keyhole.com': twoLevelDomain,
  'googlemail.com': twoLevelDomain,
  'google.net': twoLevelDomain,
  'google.org': twoLevelDomain,
  'googleratings.com': twoLevelDomain
};


var google_exact_host_function_map = {
  'www.google.com': hostFirstpath
};


function googleName(host, path) {
  debugLog('googleName(' + host + ',' + path + ')');
  // if service name isn't just the hostname in the URL
  // mostly for redirectors and services that use multiple hostnames
  var foo = google_exact_host_function_map[host];
  if (foo) {
    return foo(host, path);
  }

  var domain2 = twoLevelDomain(host);
  foo = google_two_ld_function_map[domain2];
  if (foo) {
    return foo(host, path);
  }

  return null;
}

registerService('googleServices',
                 'Breaks down URLs to public Google Services by the ' +
                 'specific Google service.  For instance ' +
                 '<tt>www.google.com/calendar</tt> or ' +
                 '<tt>mail.google.com</tt>',
                 googleName);
