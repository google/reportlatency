#!/usr/bin/perl -w
#
# Test ReportLatency::AtomicFile.pm
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
use Test::More tests => 8;
use File::Temp qw/ tempdir /;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::AtomicFile' );

my $dir = tempdir(CLEANUP => 1);
my $finalpath = "$dir/subdir/file.txt";
my $size;

{
  my $fh = new ReportLatency::AtomicFile($finalpath);
  ok(-d "$dir/subdir","$dir/subdir/");
  ok(! -e $finalpath,"$finalpath doesn't exist after file open");
  print $fh "Hello World\n";
  is(-s "$fh", 0, "file buffered still");
  close($fh);
  $size = -s "$fh";
  is($size, 12, "12 bytes written");
}
ok(-e $finalpath,"$finalpath exists after object deletion");
is(-s $finalpath, $size, "$size bytes in $finalpath");
ok(unlink($finalpath),"unlink $finalpath");
