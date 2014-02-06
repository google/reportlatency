#!/usr/bin/perl -wT
#
# Test post.pl's user agent aggregation
#
# Copyright 2013,2014 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use Test::More tests => 9;
 
BEGIN { use lib '..'; }

use_ok( 'ReportLatency::utils' );

foreach my $ua
  ('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.52 Safari/537.17',
  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.52 Safari/537.17'
  ) {
  is(aggregate_user_agent($ua),'Chrome 24', "Chrome 24  $ua");
}

foreach my $ua
  ('Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:18.0) Gecko/20100101 Firefox/18.0',
   'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:17.0) Gecko/20100101 Firefox/17.0'
  ) {
  is(aggregate_user_agent($ua),'Firefox', "Firefox  $ua");
}

foreach my $ua
  ('Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/536.26.17 (KHTML, like Gecko) Version/6.0.2 Safari/536.26.17'
  ) {
  is(aggregate_user_agent($ua),'Safari', "Safari  $ua");
}

foreach my $ua
  ('IE'
  ) {
  is(aggregate_user_agent($ua),'IE', "IE  $ua");
}

foreach my $ua
  ('Wget/1.14 (darwin12.2.0)', 'HELLO!') {
  is(aggregate_user_agent($ua),'Other',"Other  $ua");
}

