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
use Test::More tests => 42;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::utils' );


foreach my $bad ( '<script>', undef, '' ) {
  is(sanitize_service($bad),undef,
     'no ' . ($bad || 'undef') . ' from sanitize_service()');
  is(sanitize_location($bad),undef,
     'no ' . ($bad || 'undef') . ' from sanitize_location()');
  is(sanitize($bad),undef,
     'no ' . ($bad || 'undef') . ' from sanitize()');
}

foreach my $bad ( 'www.google.com/url?sa=t&q=search%20term' ) {
  is(sanitize_service($bad),undef,"no $bad from sanitize_service()");
}


foreach my $good (qw( . wiki news.google.com
                      www.google.com/calendar
		      www.google.com/calendar5) ) {
  is(sanitize_service($good),$good,"sanitize_service($good)");
  is(sanitize($good),$good,"sanitize($good)");
}

foreach my $good ('sub.example.com.', 'sub.example.com. proxy' ) {
  is(sanitize_location($good),$good,"$good location");
  is(sanitize($good),$good,"sanitize($good)");
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

is(net_class_c('1.2.3.4'), '1.2.3.0', 'net_class_c(1.2.3.4) = 1.2.3.0');
is(net_class_c('1.2.3'), undef, 'net_class_c(1.2.3) = undef');
is(net_class_c('1.2.3.4.5'), undef, 'net_class_c(1.2.3.4.5) = undef');
is(net_class_c(' 1.2.3.4'), undef, 'net_class_c( 1.2.3.4) = undef');
is(net_class_c('1.2.3.4 '), undef, 'net_class_c( 1.2.3.4) = undef');

is(reverse_dns('8.8.8.8'), 'google-public-dns-a.google.com.', 'reserve_dns()');
is(reverse_dns('0.0.0.0.0'), undef,'reserve_dns(0.0.0.0.0)==undef');
