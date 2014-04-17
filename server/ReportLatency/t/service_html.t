#!/usr/bin/perl -w
#
# Test ReportLatency::StaticView.pm's service_html()
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
use HTML::Tidy;
use Test::More tests => 9;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::StaticView' );
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

my $view = new ReportLatency::StaticView($store);

my $tidy = new HTML::Tidy;

my $no_service_html = $view->service_html('null');
is($tidy->parse('empty_service',$no_service_html), undef,
   'tidy service_html(null)');
for my $message ( $tidy->messages ) {
  print $message->as_string . "\n";
}
$tidy->clear_messages();

ok($dbh->do(q{
  INSERT INTO upload(location) VALUES("1.2.3.0");
}), 'INSERT upload');
ok($dbh->do(q{
  INSERT INTO update_request(upload,name,service,count,total)
    VALUES(1,'google.com','google.com',1,1492);
}), 'INSERT google.com request');


my $service_html = $view->service_html('google.com');
is($tidy->parse('service',$service_html), undef,
   'tidy service_html(google.com)');

for my $message ( $tidy->messages ) {
  print $message->as_string . "\n";
}
$tidy->clear_messages();

like($service_html, qr/1492/, '1492ms request latency found');
like($service_html, qr/1\.2\.3\.0/, '1.2.3.0 location found');
