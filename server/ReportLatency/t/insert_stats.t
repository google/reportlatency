#!/usr/bin/perl -w
#
# Test ReportLatency::Store.pm's insert_stats()
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
use Test::More tests => 12;

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

my $dbh;
$dbh = DBI->connect("dbi:SQLite:dbname=$dbfile",
		       {AutoCommit => 1}, '')
  or die $dbh->errstr;

my $store = new ReportLatency::Store(dbh => $dbh);

my $upload_id = $store->new_upload({ hostname => 'localhost',
				     location => 'localdomain',
				     user_agent => 'test',
				     tz => 'L0CAL',
				     version => '0.0.0',
				     options => 0 });
is($upload_id,1,'upload_id');
my ($count) = $dbh->selectrow_array("SELECT count(*) FROM upload");
is($count, 1, '1 upload');

my $reqstats = { count => 1, total => 100, response => { 304 => 1 } };
$store->add_navigation_request_stats($upload_id, 'service', 'server',
				     $reqstats);
my ($avg) =
  $dbh->selectrow_array("SELECT sum(total)/count(*) FROM navigation_request");
is($avg, 100, '100 ms average nav request latency ');
my ($redirs) =
  $dbh->selectrow_array("SELECT sum(response300) FROM navigation_request");
is($redirs, 1, '1 redir response');

$reqstats = { count => 1, total => 1000, response => { 200 => 1, 404 => 1 } };
$store->add_navigation_request_stats($upload_id, 'service', 'service',
				     $reqstats);
($avg) =
  $dbh->selectrow_array("SELECT sum(total)/count(*) FROM navigation_request");
is($avg, 550, '550 ms average nav request latency ');
my ($good) =
  $dbh->selectrow_array("SELECT sum(response200) FROM navigation_request");
is($good, 1, '1 good response');
my ($error) =
  $dbh->selectrow_array("SELECT sum(response400) FROM navigation_request");
is($error, 1, '1 error response');

$reqstats = { count => 1, total => 2000 };
$store->add_update_request_stats($upload_id, 'service', 'server',
				     $reqstats);
($avg) =
  $dbh->selectrow_array("SELECT sum(total)/count(*) FROM update_request");
is($avg, 2000, '2000 ms average update request latency ');

$reqstats = { response => { 500 => 1} };
$store->add_update_request_stats($upload_id, 'service', 'server',
				     $reqstats);
my ($bad) =
  $dbh->selectrow_array("SELECT sum(response500) FROM update_request");
is($bad, 1, '1 bad response');

my $navstats = { count => 1, total => 1500 };
$store->add_navigation_stats($upload_id, 'service', 'server', $navstats);
($avg) = $dbh->selectrow_array("SELECT sum(total)/count(*) FROM navigation");
is($avg, 1500, '1500 ms average update request latency ');

