#!/usr/bin/perl -w
#
# Test ReportLatency::utils.pm
#
# Copyright 2013 Google Inc. All Rights Reserved.
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
use Test::More tests => 19;
use ReportLatency::utils;

foreach my $bad ( '<script>' ) {
  is(sanitize_service($bad),undef,"no $bad");
}

foreach my $good (qw( . wiki news.google.com
                      www.google.com/calendar ) ) {
  is(sanitize_service($good),$good,$good);
}

foreach my $bad ( '<script>' ) {
  is(sanitize_service($bad),undef,"no $bad");
}

foreach my $good (qw( wiki news.google.com
                      www.google.com/calendar ) ) {
  is(sanitize_service($good),$good,$good);
}

is(service_path("news.google.com",".png"),
   "news.google.com.png");
is(service_path("www.google.com/calendar",".png"),
   "www.google.com/calendar.png");

is(average(undef,undef), '', "average undef");
is(average(100,undef), '', "average undef count");
is(average(100.1,2), 50, "average");

is(mynum(undef), "", "mynum undef");
is(mynum(10), 10, "mynum 10");

is(myround(undef), "", "myround undef");
is(myround(10.6), 11, "myround 10.6");
is(myround(10.6), 11, "myround 10.6");
