#!/usr/bin/perl -w
#
# Test ReportLatency::Spectrum.pm
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
use Test::More tests => 36;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::Spectrum' );


my $spectrum = new ReportLatency::Spectrum( logarithmic => 0 );

isa_ok($spectrum, 'ReportLatency::Spectrum');
can_ok($spectrum, qw( add png ));

is($spectrum->width(),500,"default width()");
is($spectrum->height(),250,"default height()");
is($spectrum->duration(),14*24*3600,"default duration()");
is($spectrum->ceiling(),30000,"default ceiling()");

is($spectrum->_y(-1),undef,"_y(-1)=undef");
is($spectrum->_y(0),0,"_y(0)=0");
is($spectrum->_y(6000),50,"_y(6000)=50");
is($spectrum->_y(100000),$spectrum->height()-1,"_y(>ceiling) =~ height");

is($spectrum->_x(0),undef,"_x(unix epoch) == undef");
is($spectrum->_x(time-10),$spectrum->width()-1,"_x(time-10) =~ width");
is($spectrum->_x(time - $spectrum->duration()/2),
   int(($spectrum->width()-1)/2),
   "_x(duration/2) =~ width/2");
is($spectrum->_x(time),$spectrum->width()-1,"_x(time) =~ width");
is($spectrum->_x(time+10),$spectrum->width()-1,"_x(time+10) =~ width");

is($spectrum->maxval(), 0, "0 maxval()");
is($spectrum->add(0,0), undef, "add(outside duration) == undef");
is($spectrum->add(time,-1), undef, "add(outside measurement) == undef");
is($spectrum->maxval(), 0, "0 maxval() still");
is($spectrum->add(time,0), 1, "add(valid point) == 1");
is($spectrum->maxval(), 1, "new 1 maxval()");
is($spectrum->add(time,0, 2), 3, "add(valid point) == 3");
is($spectrum->maxval(), 3, "new maxval()");
is($spectrum->add(time - $spectrum->duration()/2,
		  $spectrum->ceiling()/2, 2),
   2,
   "add(valid halfway avg) == 2");
is($spectrum->maxval(), 3, "prior maxval() still current");


my $img = $spectrum->img();
isa_ok($img, 'GD::Image', "img() returns GD::Image");


$spectrum = new ReportLatency::Spectrum( logarithmic => 1,
					 ceiling => 10000,
					 floor => 100 );

is($spectrum->_y(-1),undef,"log _y(-1)=undef");
is($spectrum->_y(0),0,"log _y(0)=0");
is($spectrum->_y(99.999),0,"log _y(99.999)=0");
is($spectrum->_y(100.001),0,"log _y(100.001)=0");
is($spectrum->_y(999.999),124,"log _y(999.999)=124");
is($spectrum->_y(1000.001),125,"log _y(1000.001)=125");
is($spectrum->_y(9999.999),249,"log _y(9999.999)=249");
is($spectrum->_y(10000.001),249,"log _y(1000.001)=249");
is($spectrum->_y(100000),$spectrum->height()-1,"log _y(>ceiling) =~ height");
