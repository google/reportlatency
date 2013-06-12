#!/usr/bin/perl -w
#
# Test latencyspectrum.pl
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
use DBI;
use Test::More tests => 11;
use File::Temp qw(tempfile tempdir);

$ENV{'PATH'} = '/usr/bin';

push(@INC,'.');

require_ok('./latencyspectrum.pl');

my $dir = tempdir(CLEANUP => 1);
mkdir("$dir/data");
mkdir("$dir/batch");
my $dbfile="$dir/data/latency.sqlite3";

{
  open(my $sqlite3,"|-",'sqlite3',$dbfile) or die $!;
  open(my $sql,'<','../cgi/latency.sql') or die $!;
  while (my $line = $sql->getline) {
    print $sqlite3 $line;
  }
  close($sql);
  ok(close($sqlite3),'latency schema');
}

{
  open(my $sqlite3,"|-",'sqlite3',"$dir/data/latency.sqlite3")
    or die $!;
  print $sqlite3 <<EOF;
INSERT INTO report(final_name,navigation_count,navigation_total) VALUES('service',3,666);
INSERT INTO report(final_name,navigation_count,navigation_total) VALUES('service',3,999);
UPDATE report SET timestamp=DATETIME('now','-1 days') WHERE navigation_total=999;
INSERT INTO report(final_name,navigation_count,navigation_total) VALUES('service',3,333);
UPDATE report SET timestamp=DATETIME('now','-2 days') WHERE navigation_total=333;
INSERT INTO report(final_name,navigation_count,navigation_total) VALUES('slow',1,6666);
UPDATE report SET timestamp=DATETIME('now','-1 days') WHERE navigation_total=6666;
EOF

  ok(close($sqlite3),"latency data added");
  sleep(1);
}

chdir("$dir/batch");

main();

open(my $id,"-|","identify", "latency-spectrum.png") or die $!;
my $line = $id->getline;
like($line,
     qr/^latency-spectrum\.png PNG \d+x\d+/,
     'PNG');

ok(unlink("$dir/batch/latency-spectrum.png"),"unlink latency-spectrump.png");
ok(unlink("$dir/batch/untagged.png"),"unlink untagged.png");
unlink("$dir/data/latency.sqlite3");
rmdir("$dir/data");
ok(unlink("$dir/batch/service/service.png"),"rmdir service/service.png");
ok(rmdir("$dir/batch/service"),"rmdir service/");
ok(rmdir("$dir/batch/location"),"rmdir location/");
ok(rmdir("$dir/batch"),"rmdir batch/");
ok(rmdir($dir),"rmdir tmpdir");

