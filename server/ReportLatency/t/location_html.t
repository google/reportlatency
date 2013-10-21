#!/usr/bin/perl -w
#
# Test ReportLatency::Store.pm
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
use HTML::Tidy;
use Test::More tests => 9;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::Store' );
use_ok( 'ReportLatency::StaticView' );


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
		       {AutoCommit => 0}, '')
  or die $dbh->errstr;

ok($dbh->begin_work,'begin transaction');

my $store = new ReportLatency::Store(dbh => $dbh);
my $view = new ReportLatency::StaticView($store);


my $tidy = new HTML::Tidy;

ok($dbh->do(q{
  INSERT INTO tag(tag,name) VALUES('Google','google.com');
}),'INSERT Google tag');
ok($dbh->do(q{
  INSERT INTO report(timestamp,remote_addr,name,final_name,request_count,request_total) VALUES('9999','office.google.com.', 'google.com','google.com',1,1000);
}), 'INSERT google.com report');
ok($dbh->commit,'commit');


my $location_html = $view->location_html('office.google.com');
is($tidy->parse('office',$location_html), undef,
   'tidy location_html(office.google.com)');

for my $message ( $tidy->messages ) {
  print $message->as_string . "\n";
}
$tidy->clear_messages();

ok($dbh->rollback,'rollback transaction');
