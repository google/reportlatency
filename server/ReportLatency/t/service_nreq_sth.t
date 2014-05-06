#!/usr/bin/perl -w
#
# Test ReportLatency::Store.pm's service_nreq_latencies_sth()
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
use Test::More tests => 11;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::Store' );


my $dir = tempdir(CLEANUP => 1);
my $dbfile = "$dir/latency.sqlite3";
{
  open(my $sqlite3,"|-",'sqlite3',$dbfile) or die $!;
  foreach my $source qw(sqlite3.sql views-sqlite3.sql) {
    open(my $sql,'<',"../sql/$source") or die $!;
    while (my $line = $sql->getline) {
      print $sqlite3 $line;
    }
    close($sql);
  }
  ok(close($sqlite3),'latency schema');
}

my $dbh;
$dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", {}, '')
  or die $dbh->errstr;

my $store = new ReportLatency::Store(dbh => $dbh);


ok($dbh->do(q{
  INSERT INTO upload(location) VALUES("1.2.3.0");
}), 'INSERT upload');
ok($dbh->do(q{
  INSERT INTO navigation_request(upload,name,service,count,total,low,high)
    VALUES(1,'mail.google.com','mail.google.com',3,2100,600,800);
}), 'INSERT mail.google.com navigation_request');


my $sth = $store->service_nreq_latencies_sth();
$sth->execute('mail.google.com','0 seconds', "-300 seconds");
my $row = $sth->fetchrow_hashref;

cmp_ok($row->{timestamp}, '<=', time, 'timestamp <= now');
cmp_ok($row->{timestamp}, '>', time-300, 'timestamp > now-300');
is($row->{count}, 3, 'count');
is($row->{total}, 2100, 'total');
is($row->{low}, 600, 'low');
is($row->{high}, 800, 'high');

$row = $sth->fetchrow_hashref;
is($row, undef, 'last row');
