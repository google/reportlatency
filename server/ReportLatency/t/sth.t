#!/usr/bin/perl -w
#
# Test ReportLatency::Store.pm's *_sth() methods
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
use HTML::Tidy;
use Test::More tests => 160;
use Data::Dumper;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::Store' );


my $dir = tempdir(CLEANUP => 1);
my $dbfile = "$dir/latency.sqlite3";
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

my $store = new ReportLatency::Store(dsn => "dbi:SQLite:dbname=$dbfile");
my $dbh = $store->{dbh};

ok($dbh->do(q{
  INSERT INTO upload(location) VALUES("1.2.3.0");
}), 'INSERT upload');
ok($dbh->do(q{
  INSERT INTO navigation(upload,name,service,count,total)
    VALUES(1,'mail.google.com','mail.google.com',1,2038);
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


my $sth = $store->untagged_nav_latencies_sth();
$sth->execute('-300 seconds', "0 seconds");
my $row = $sth->fetchrow_hashref;
is($row->{count}, 1, 'total nav latency count');
is($row->{total}, 2038, 'total');
is($row->{low}, undef, 'low');
is($row->{high}, undef, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last untagged nav latency row');

$sth = $store->untagged_nreq_latencies_sth();
$sth->execute('-300 seconds', "0 seconds");
$row = $sth->fetchrow_hashref;
is($row->{count}, 3, 'total nreq latency count');
is($row->{total}, 2100, 'total');
is($row->{low}, 600, 'low');
is($row->{high}, 800, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last untagged nreq latency row');



ok($dbh->do(q{
  INSERT INTO tag(service,tag) VALUES('mail.google.com','Mail');
}), 'INSERT Mail tag');


$sth = $store->untagged_ureq_latencies_sth();
$sth->execute('-300 seconds', "0 seconds");
$row = $sth->fetchrow_hashref;
is($row->{count}, 10, 'untagged ureq latency count');
is($row->{total}, 3330, 'total');
is($row->{low}, undef, 'low');
is($row->{high}, undef, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last untagged ureq latency row');

$sth = $store->service_nav_latencies_sth();
$sth->execute("-300 seconds", '0 seconds', 'mail.google.com');
$row = $sth->fetchrow_hashref;
is($row->{count}, 1, 'mail.google.com nav latency count');
is($row->{total}, 2038, 'total');
is($row->{low}, undef, 'low');
is($row->{high}, undef, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last mail.google.com nav latency row');


$sth = $store->tag_nav_latencies_sth();
$sth->execute("-300 seconds", '0 seconds', 'Mail');
$row = $sth->fetchrow_hashref;
is($row->{count}, 1, 'Mail count');
is($row->{total}, 2038, 'total');
is($row->{low}, undef, 'low');
is($row->{high}, undef, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last Mail nav latency row');


$sth = $store->tag_nreq_latencies_sth();
$sth->execute('-300 seconds', "0 seconds", 'Mail');
$row = $sth->fetchrow_hashref;
is($row->{count}, 3, 'Mail nreq latency count');
is($row->{total}, 2100, 'total');
is($row->{low}, 600, 'low');
is($row->{high}, 800, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last Mail nreq latency row');


$sth = $store->tag_ureq_latencies_sth();
$sth->execute('-300 seconds', "0 seconds", 'Mail');
$row = $sth->fetchrow_hashref;
is($row->{count}, 10, 'Mail ureq latency count');
is($row->{total}, 2220, 'total');
is($row->{low}, 100, 'low');
is($row->{high}, 300, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last Mail ureq latency row');


$sth = $store->location_nav_latencies_sth();
$sth->execute("-300 seconds", '0 seconds', '1.2.3.0');
$row = $sth->fetchrow_hashref;
is($row->{count}, 1, 'location 1.2.3.0 nav latency count');
is($row->{total}, 2038, 'total');
is($row->{low}, undef, 'low');
is($row->{high}, undef, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last location 1.2.3.0 nav latency row');

$sth = $store->total_nav_latencies_sth();
$sth->execute($store->db_timestamp(time-300), $store->db_timestamp(time+2));
$row = $sth->fetchrow_hashref;
is($row->{count}, 1, 'total nav latency count');
is($row->{total}, 2038, 'total');
is($row->{low}, undef, 'low');
is($row->{high}, undef, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last total nav latency row');


$sth = $store->untagged_nav_latencies_sth();
$sth->execute("-300 seconds", '0 seconds');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last untagged nav latency row');


$sth = $store->service_nreq_latencies_sth();
$sth->execute("-300 seconds", '0 seconds', 'mail.google.com');
$row = $sth->fetchrow_hashref;
is($row->{count}, 3, 'mail.google.com nreq count');
is($row->{total}, 2100, 'total');
is($row->{low}, 600, 'low');
is($row->{high}, 800, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last mail.google.com nreq latency row');


$sth = $store->total_nreq_latencies_sth();
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


$sth = $store->service_ureq_latencies_sth();
$sth->execute("-300 seconds", '0 seconds', 'mail.google.com');
$row = $sth->fetchrow_hashref;
is($row->{count}, 10, 'mail.google.com ureq count');
is($row->{total}, 2220, 'total');
is($row->{low}, 100, 'low');
is($row->{high}, 300, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last mail.google.com ureq latency row');

{
  $sth = $store->total_ureq_latencies_sth();
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

$sth = $store->location_nreq_latencies_sth();
$sth->execute("-300 seconds", '0 seconds', '3.2.1.0');
is($sth->fetchrow_hashref, undef, 'no nreq for 3.2.1.0 location');
$sth->execute("-300 seconds", '0 seconds', '1.2.3.0');
$row = $sth->fetchrow_hashref;
is($row->{count}, 3, 'location nreq count');
is($row->{total}, 2100, 'total');
is($row->{low}, 600, 'low');
is($row->{high}, 800, 'high');
cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
$row = $sth->fetchrow_hashref;
is($row, undef, 'last location nreq latency row');


{
  $sth = $store->location_ureq_latencies_sth();
  $sth->execute("-300 seconds", '0 seconds', '3.2.1.0');
  is($sth->fetchrow_hashref, undef, 'nothing for 3.2.1.0 location');
  ok($sth->finish, 'finish empty location ureq latencies');
  $sth->execute("-300 seconds", '0 seconds', '1.2.3.0');
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


$sth = $store->extension_version_sth();
$sth->execute(time-300, time);
for (my $i=0; $i<3; $i++) {
  $row = $sth->fetchrow_hashref;
  print STDERR Dumper($row);
  is($row->{measure}, undef, 'undef extension_version');
  is($row->{amount}, 1, '1 extension_version');
  cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
  cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
}
$row = $sth->fetchrow_hashref;
is($row, undef, 'last extension_version row');


$sth = $store->user_agent_sth();
$sth->execute(time-300, time);
for (my $i=0; $i<3; $i++) {
  $row = $sth->fetchrow_hashref;
  is($row->{measure}, undef, 'undef user_agent');
  is($row->{amount}, 1, '1 user_agent');
  cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
  cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
}
$row = $sth->fetchrow_hashref;
is($row, undef, 'last user_agent row');


$sth = $store->service_select_sth();
$sth->execute('mail.google.com');
$row = $sth->fetchrow_hashref;
is($row->{name}, 'mail.google.com', 'mail.google.com server name');
is($row->{ureq_count}, 10, '10 ureqs');
is($row->{ureq_latency}, 222, 'ureq latency');
is($row->{nav_count}, 1, '1 nav');
is($row->{nav_latency}, 2038, 'nav latency');
$row = $sth->fetchrow_hashref;
is($row, undef, "last mail.google.com table row");


$sth = $store->summary_meta_sth();
$sth->execute($store->db_timestamp(time-300), $store->db_timestamp(time));
$row = $sth->fetchrow_hashref;

is($row->{tag}, 'total', 'summary meta tagged "total"');
is($row->{services}, 2, '2 services');
is($row->{nav_count}, 1, '1 nav');
is($row->{nav_latency}, 2038, 'nav latency');
is($row->{nreq_count}, 3, '3 nreqs');
is($row->{nreq_latency}, 700, 'nreq latency');
is($row->{ureq_count}, 20, '20 ureqs');
is($row->{ureq_latency}, 5550/20, 'ureq latency');
$row = $sth->fetchrow_hashref;
is($row, undef, "one row from summary metadata");


