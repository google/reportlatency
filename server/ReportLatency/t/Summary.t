#!/usr/bin/perl -w
#
# Test ReportLatency::Summary.pm
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
use Test::More tests => 63;
use Data::Dumper;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::Summary' );
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
my $qobj = new ReportLatency::Summary($store,$begin,$end);
isa_ok($qobj, 'ReportLatency::Summary');

my $dbh = $store->{dbh};
ok($dbh->do(q{
  INSERT INTO upload(location) VALUES("1.2.3.0");
}), 'INSERT upload');
ok($dbh->do(q{
  INSERT INTO navigation(upload,name,service,count,total,m10000,response200)
    VALUES(1,'mail.google.com','mail.google.com',1,2038,1,1);
}), 'INSERT mail.google.com navigation');
ok($dbh->do(q{
  INSERT INTO navigation_request(upload,name,service,count,total,low,high)
    VALUES(1,'mail.google.com','mail.google.com',3,2100,600,800);
}), 'INSERT mail.google.com navigation_request');
ok($dbh->do(q{
  INSERT INTO upload(location) VALUES("1.2.3.0");
}), 'INSERT upload');
ok($dbh->do(q{
  INSERT INTO update_request(upload,name,service,count,total,low,high)
    VALUES(2,'mail.google.com','mail.google.com',10,2220,100,300);
}), 'INSERT mail.google.com update_request');
ok($dbh->do(q{
  INSERT INTO upload(location) VALUES("1.2.3.0");
}), 'INSERT upload');
ok($dbh->do(q{
  INSERT INTO update_request(upload,name,service,count,total)
    VALUES(3,'news.google.com','news.google.com',10,3330);
}), 'INSERT news.google.com update_request');

my $sth = $qobj->nav_latencies();
$sth->execute($begin, $end);
my $row = $sth->fetchrow_hashref;
is($row->{count}, 1, 'total nav latency count');
is($row->{total}, 2038, 'total');
is($row->{low}, undef, 'low');
is($row->{high}, undef, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last total nav latency row');

$sth = $qobj->nav_latency_histogram();
$row = $sth->fetchrow_hashref;
ok($row, "got a row from nav_latency_histogram");
print STDERR "nav_latency_histogram = ";
print STDERR Dumper($row);
is($row->{amount}, 1, '1 navigation');
is($row->{measure}, '10s', ' in 10s bin');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last nav_latency_histogram row');

$sth = $qobj->nreq_latencies();
$sth->execute($store->db_timestamp(time-300), $store->db_timestamp(time));
$row = $sth->fetchrow_hashref;
is($row->{count}, 3, 'total nreq count');
is($row->{total}, 2100, 'total');
is($row->{low}, 600, 'low');
is($row->{high}, 800, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last total nreq latency row');

{
  $sth = $qobj->ureq_latencies();
  $sth->execute($store->db_timestamp(time-300), $store->db_timestamp(time));
  my ($count,$total,$rows);
  while (my $row = $sth->fetchrow_hashref) {
    $count += $row->{count};
    $total += $row->{total};
    $rows++;
    cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
    cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
  }
  is($rows, 2, '2 total ureq latency rows');
  is($count, 20, '20 total ureq count');
  is($total, 2220+3330, '5550 ms total ureq latency');
}

$sth = $qobj->extension_version_histogram();
$sth->execute($store->db_timestamp(time-300), $store->db_timestamp(time));
for (my $i=0; $i<3; $i++) {
  $row = $sth->fetchrow_hashref;
  is($row->{measure}, undef, 'undef extension_version');
  is($row->{amount}, 1, '1 extension_version');
  cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
  cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
}
$row = $sth->fetchrow_hashref;
is($row, undef, 'last extension_version row');


$sth = $qobj->user_agent_histogram();
$sth->execute($store->db_timestamp(time-300), $store->db_timestamp(time));
for (my $i=0; $i<3; $i++) {
  $row = $sth->fetchrow_hashref;
  is($row->{measure}, undef, 'undef user_agent');
  is($row->{amount}, 1, '1 user_agent');
  cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
  cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
}
$row = $sth->fetchrow_hashref;
is($row, undef, 'last user_agent row');

