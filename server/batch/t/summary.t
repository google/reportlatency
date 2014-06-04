#!/usr/bin/perl -w
#
# Test summary.pl
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
use DBI;
use Test::More tests => 15;
use File::Temp qw(tempfile tempdir);

$ENV{'PATH'} = '/usr/bin';

BEGIN { use lib ".."; }

require_ok('./summary.pl');

my $dir = tempdir(CLEANUP => 1);
mkdir("$dir/data");
my $dbfile="$dir/data/backup.sqlite3";

{
  open(my $sqlite3,"|-",'sqlite3',$dbfile) or die $!;
  foreach my $source (qw(sqlite3.sql views-sqlite3.sql)) {
    open(my $sql,'<',"../sql/$source") or die $!;
    while (my $line = $sql->getline) {
      print $sqlite3 $line;
    }
    close($sql);
  }
  ok(close($sqlite3),'latency schema');
}

{
  open(my $sqlite3,"|-",'sqlite3',$dbfile)
    or die $!;
  print $sqlite3 <<EOF;
INSERT INTO upload(location,version,user_agent)
 VALUES('office.google.com.','1.5.4','Chrome 24');
INSERT INTO upload(location,version,user_agent)
 VALUES('office.google.com.','1.5.4','Chrome 24');
INSERT INTO upload(location,version,user_agent)
 VALUES('office.google.com.','1.5.4','Chrome 24');
UPDATE upload SET timestamp=DATETIME('now','-2 days') WHERE id=1;
UPDATE upload SET timestamp=DATETIME('now','-1 days') WHERE id=2;
INSERT INTO navigation(upload,service,count,total) VALUES(1,'service',3,333);
INSERT INTO navigation(upload,service,count,tabclosed,total) VALUES(2,'service',3,1,999);
INSERT INTO navigation(upload,service,count,total) VALUES(3,'service',3,666);
INSERT INTO navigation(upload,service,count,total) VALUES(3,'slow',1,6666);
INSERT INTO tag(service,tag) VALUES('service','Company');
EOF

  ok(close($sqlite3),"latency data added");
  sleep(1);
}

chdir($dir);

main();

open(my $id,"-|","identify", "$dir/tags/summary/nav_spectrum.png") or die $!;
my $line = $id->getline;
like($line,
     qr/nav_spectrum\.png PNG \d+x\d+/,
     'PNG');

unlink($dbfile);
rmdir("$dir/data");
ok(unlink("$dir/tags/summary/nav_spectrum.png"),
   "unlink summary/nav_spectrum.png");
ok(unlink("$dir/tags/summary/nav_latency.png"),
   "unlink summary/nav_latency.png");
ok(unlink("$dir/tags/summary/nav_error.png"),
   "unlink summary/nav_error.png");
ok(unlink("$dir/tags/summary/ureq_spectrum.png"),
   "rm summary/ureq_spectrum.png");
ok(unlink("$dir/tags/summary/nreq_spectrum.png"),
   "rm summary/nreq_spectrum.png");
ok(unlink("$dir/tags/summary/extensions.png"),"unlink summary/extensions.png");
ok(unlink("$dir/tags/summary/useragents.png"),"unlink summary/useragents.png");
ok(unlink("$dir/tags/summary/index.html"),"unlink summary/index.html");
ok(rmdir("$dir/tags/summary"),"rmdir summary/");
ok(rmdir("$dir/tags"),"rmdir tags/");
ok(rmdir($dir),"rmdir tmpdir");
