
/**
 * @fileoverview google_tests.js has unit tests for the functions in
 *    google_services.js.
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

test('googleName', function() {
       equal(googleName
             ('mail.google.com', 'mail/u/0/?shva=1#search/qunit'),
             'mail.google.com',
             'mail.google.com');
       equal(googleName
             ('www.google.com', 'calendar/render?tab=mc'),
             'www.google.com/calendar',
             'www.google.com/calendar');
       equal(googleName
             ('www.google.com', '#hl=en'),
             'www.google.com',
             'www.google.com/#');
       equal(googleName
             ('www.google.com', 'search?q=css image'),
             'www.google.com/search',
             'www.google.com/search');
       equal(googleName
             ('goto.google.com', 'redir'),
             'goto.google.com',
             'goto.google.com/redir');

       // everything under these domains is just counted as one service
       var domain_services = ['youtube.com', 'youtube-nocookie.com',
                              'youtu.be', 'ytimg.com',
                              'doubleclick.net',
                              'googlesyndication.com', 'admob.com',
                              'googletagservices.com',
                              'googleadservices.com',
                              'google-analytics.com', 'urchin.com',
                              'googletagmanager.com',
                              'gstatic.com',
                              'goo.gl', 'g.co',
                              'googlecommerce.com',
                              'android.com',
                              'googleapis.com',
                              'appspot.com', 'withgoogle.com',
                              'blogger.com', 'blogblog.com',
                              'blogspot.com',
                              'googlecode.com', 'googlesource.com',
                              'googlegroups.com',
                              'googleusercontent.com', 'ggpht.com',
                              'googledrive.com',
                              'gmail.com', 'googlemail.com',
                              'googleitahosted.com', 'itasoftware.com',
                              'widevine.tv', 'widevine.com',
                              'keyhole.com',
                              'google.net', 'google.org'
                              ];
       for (var i = 0; i < domain_services.length; i++) {
         equal(googleName
               ('www.' + domain_services[i], 'path?args'),
               domain_services[i],
               domain_services[i]);
       }
       equal(googleName
             ('service.company.com', 'path'),
             null,
             '!service.company.com');
     });

