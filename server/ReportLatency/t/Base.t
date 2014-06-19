#!/usr/bin/perl -w
#
# Test ReportLatency::Base.pm
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
use File::Temp qw(tempfile tempdir);
use Test::More tests => 19;
use Data::Dumper;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::Base' );
use ReportLatency::Store;


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

my $b = time-300;
my $e = time+300;
my $begin = $store->db_timestamp($b);
my $end = $store->db_timestamp($e);
my $qobj = new ReportLatency::Base($store,$begin,$end);
isa_ok($qobj, 'ReportLatency::Base');


my $sth = $qobj->nav_latencies();
isa_ok($sth, 'DBI::st');
my $row = $sth->fetchrow_hashref;
is($row, undef, 'last nav latency row');

$sth = $qobj->nav_latency_histogram();
isa_ok($sth, 'DBI::st');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last nav_latency_histogram row');

$sth = $qobj->nreq_latencies();
$row = $sth->fetchrow_hashref;
is($row, undef, 'last nreq latency row');

$sth = $qobj->ureq_latencies();
$row = $sth->fetchrow_hashref;
is($row, undef, 'last nreq row');

my $meta = $qobj->meta();
ok($meta, '%meta');

$sth = $qobj->tag();
$row = $sth->fetchrow_hashref;
is($row->{tag}, 'untagged', 'tag untagged');
is($row->{services}, 0, '0 services');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last tag row');

$sth = $qobj->location();
$row = $sth->fetchrow_hashref;
is($row, undef, 'last location row');

$sth = $qobj->nav_response_histogram();
$row = $sth->fetchrow_hashref;
is($row, undef, 'last nav_response_histogram row');

$sth = $qobj->nreq_response_histogram();
$row = $sth->fetchrow_hashref;
is($row, undef, 'last nreq_response_histogram row');

$sth = $qobj->ureq_response_histogram();
$row = $sth->fetchrow_hashref;
is($row, undef, 'last ureq_response_histogram row');

$sth = $qobj->nreq_latency_histogram();
$row = $sth->fetchrow_hashref;
is($row, undef, 'last nreq_latency_histogram row');

$sth = $qobj->ureq_latency_histogram();
$row = $sth->fetchrow_hashref;
is($row, undef, 'last ureq_latency_histogram row');

