#!/usr/bin/perl -w
#
# Test ReportLatency::StackedGraph.pm
#
# Copyright 2014 Google Inc. All Rights Reserved.
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
use Test::More tests => 16;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::StackedGraph' );


my $graph = new ReportLatency::StackedGraph( );

isa_ok($graph, 'ReportLatency::StackedGraph');
can_ok($graph, qw( add add_row img ));

is($graph->width(),1000,"default width()");
is($graph->height(),250,"default height()");
is($graph->duration(),14*24*3600,"default duration()");

is($graph->_x(0),undef,"_x(unix epoch) == undef");
is($graph->_x(time-10),$graph->width()-1,"_x(time-10) =~ width");
is($graph->_x(time - $graph->duration()/2),
   int(($graph->width()-1)/2),
   "_x(duration/2) =~ width/2");
is($graph->_x(time),$graph->width()-1,"_x(time) =~ width");
is($graph->_x(time+10),$graph->width()-1,"_x(time+10) =~ width");

my $now = time;

is($graph->add(0,'measure',0), undef, "add(outside duration) == undef");
is($graph->add($now,'measure',-1), undef, "add(outside measurement) == undef");
is($graph->add($now,'good',1), 1, "add(valid point) == 1");
is($graph->add($now,'good', 2), 3, "add(valid point) == 3");

my $img = $graph->img();
isa_ok($img, 'GD::Image', "img() returns GD::Image");

