#!/usr/bin/perl -w
#
# Test ReportLatency::StaticView.pm
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
use Test::More tests => 5;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::StaticView' );

my $store = {};
my $view = new ReportLatency::StaticView($store);
isa_ok($view, 'ReportLatency::StaticView');

is($view->service_img_url('www.company.com'), 'navigation.png',
   'hostname passthrough png image name');
is($view->service_img_url('www.company.com/home'), 'navigation.png',
   'relative path to png from service name with path');
is($view->service_img_url('www.company.com/home/person'), 'navigation.png',
   'relative 2-level path to png from service name with path');
