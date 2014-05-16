#!/usr/bin/perl -w
#
# Test ReportLatency::Store.pm
#
# Copyright 2013,2014 Google Inc. All Rights Reserved.
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
use Test::More tests => 7;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::Store' );


my $dir = tempdir(CLEANUP => 1);
my $dbfile = "$dir/latency.sqlite3";
{
  open(my $sqlite3,"|-",'sqlite3',$dbfile) or die $!;
  open(my $sql,'<','../sql/sqlite3.sql') or die $!;
  while (my $line = $sql->getline) {
    print $sqlite3 $line;
  }
  close($sql);
  ok(close($sqlite3),'latency schema');
}

my $store = new ReportLatency::Store(dsn => "dbi:SQLite:dbname=$dbfile");

isa_ok($store, 'ReportLatency::Store');
isa_ok($store->{dbh}, 'DBI::db');

is($store->aggregate_remote_address('8.8.8.8'),'google.com.',
   'aggregate_remote_address(8.8.8.8)');
is($store->aggregate_remote_address('8.8.8.8'),'google.com.',
   '2nd aggregate_remote_address(8.8.8.8)');
is($store->aggregate_remote_address('0.0.0.1'),'0.0.0.0',
   'aggregate_remote_address(0.0.0.1)');

