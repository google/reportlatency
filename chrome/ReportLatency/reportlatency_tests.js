
/**
 * @fileoverview reportlatency_tests.js has unit tests for the functions in
 *    functions.js.
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

test('topLevelDomain', function() {
  equal(topLevelDomain('mail.google.com'),
      'com',
      '.com');
  equal(topLevelDomain('localhost'), null, 'localhost');
  equal(topLevelDomain('.'), null, '.');
});

test('usDomain', function() {
  equal(usDomain('www.ci.sanmateo.ca.us'),
      'ci.sanmateo.ca.us', 'ci.sanmateo.ca.us');
  equal(usDomain('co.sanmateo.ca.us'),
      'co.sanmateo.ca.us', 'co.sanmateo.ca.us');
  equal(usDomain('www.state.ak.us'),
      'state.ak.us', 'state.ak.us');
});


test('defaultDomain', function() {
  equal(defaultDomain('ci.boston.ma.us'),
      'ci.boston.ma.us', 'ci.boston.ma.us');
  equal(defaultDomain('www.google.co.uk'),
      'google.co.uk', 'google.co.uk'),
  equal(defaultDomain('www.w3c.org'), 'w3c.org', 'w3c.org');
});

test('isWebUrl', function() {
  equal(isWebUrl('chrome-extension://dogebkafemeemimlegokpipjpincehpi/' +
      'options.html'),
      false, '!chrome-extension:');
  equal(isWebUrl('https://www.google.com/calendar/hello'),
      true, 'https:');
  equal(isWebUrl('http://www.google.com'),
      true, 'http:');
});

test('timeZone', function() {
  equal(timeZone(Date()),
      Date().match(/\(([A-Z]{1,5})\)/)[1],
      'current timezone abbreviation');
  equal(timeZone('Thu Mar 28 2013 15:02:56 GMT-0700 (PDT)'),
      'PDT',
      'PDT');
  equal(timeZone(null),
      null,
      'NULL');

});
