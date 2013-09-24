#!/usr/bin/perl -w
#
# Test ReportLatency::Store.pm's latency_dbh()
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
use File::Temp qw(tempfile tempdir);
use Test::More tests => 6;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::utils' );


my $dir = tempdir(CLEANUP => 1);

{
  my $dbh = latency_dbh();
  ok(!$dbh,"no writeable database found");
}

mkdir("$dir/data");
mkdir("$dir/cgi-bin");
chdir("$dir/cgi-bin");
open(my $fh, '>', "$dir/data/latency.sqlite3") or die;
close($fh);

{
  my $dbh = latency_dbh();

  isa_ok($dbh, 'DBI::db');
}

ok(unlink("$dir/data/latency.sqlite3"),"unlink");
ok(rmdir("$dir/data"),"rmdir data");
chdir;
ok(rmdir("$dir/cgi-bin"),"rmdir cgi-bin");
