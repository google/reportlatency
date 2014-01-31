#!/usr/bin/perl -w
#
# Test generate-static-content.pl
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
use Test::More tests => 16;
use File::Temp qw(tempfile tempdir);

$ENV{'PATH'} = '/usr/bin';

BEGIN { use lib ".."; }

require_ok('./generate-static-content.pl');

my $dir = tempdir(CLEANUP => 1);
mkdir("$dir/data");
my $dbfile="$dir/data/backup.sqlite3";

{
  open(my $sqlite3,"|-",'sqlite3',$dbfile) or die $!;
  open(my $sql,'<','../sql/sqlite3.sql') or die $!;
  while (my $line = $sql->getline) {
    print $sqlite3 $line;
  }
  close($sql);
  ok(close($sqlite3),'latency schema');
}

{
  open(my $sqlite3,"|-",'sqlite3',$dbfile)
    or die $!;
  print $sqlite3 <<EOF;
INSERT INTO upload(location) VALUES('office.google.com');
INSERT INTO upload(location) VALUES('office.google.com');
INSERT INTO upload(location) VALUES('office.google.com');
UPDATE upload SET timestamp=DATETIME('now','-2 days') WHERE id=1;
UPDATE upload SET timestamp=DATETIME('now','-1 days') WHERE id=2;
INSERT INTO navigation(upload,service,count,total) VALUES(1,'service',3,333);
INSERT INTO navigation(upload,service,count,total) VALUES(2,'service',3,999);
INSERT INTO navigation(upload,service,count,total) VALUES(3,'service',3,666);
INSERT INTO navigation(upload,service,count,total) VALUES(3,'slow',1,6666);
EOF

  ok(close($sqlite3),"latency data added");
  sleep(1);
}

chdir($dir);

main();

open(my $id,"-|","identify", "$dir/tags/summary.png") or die $!;
my $line = $id->getline;
like($line,
     qr/summary\.png PNG \d+x\d+/,
     'PNG');

unlink($dbfile);
rmdir("$dir/data");
ok(unlink("$dir/locations/office.google.com.png"),"unlink location png");
ok(unlink("$dir/locations/office.google.com..html"),"unlink location html");
ok(rmdir("$dir/locations"),"rmdir locations/");
ok(unlink("$dir/services/service.png"),"rmdir service/service.png");
ok(unlink("$dir/services/service.html"),"unlink service.html");
ok(rmdir("$dir/services"),"unlink services/");
ok(unlink("$dir/tags/summary.png"),"unlink summary.png");
ok(unlink("$dir/tags/summary.html"),"unlink summary.html");
ok(unlink("$dir/tags/untagged.html"),"unlink untagged.html");
ok(unlink("$dir/tags/untagged.png"),"unlink untagged.png");
ok(rmdir("$dir/tags"),"rmdir tags/");
ok(rmdir($dir),"rmdir tmpdir");


