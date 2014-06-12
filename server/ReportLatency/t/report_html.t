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
use CGI;
use DBI;
use File::Temp qw(tempfile tempdir);
use Test::More tests => 9;
use HTML::Tidy;
use Data::Dumper;

BEGIN {
  use lib '..';
}

use_ok( 'ReportLatency::Store' );
use_ok( 'ReportLatency::StaticView' );
use_ok( 'ReportLatency::Summary' );

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

my $view = new ReportLatency::StaticView($store);


ok($dbh->do(q{
  INSERT INTO upload(location) VALUES('office.google.com');
}), 'INSERT google.com upload');

ok($dbh->do(q{
  INSERT INTO navigation(upload,name,service,count,total) VALUES(1,'google.com','google.com',2,1998);
}), 'INSERT google.com report');

my $qobj = new ReportLatency::Summary($store,$store->db_timestamp(time-300),
				      $store->db_timestamp(time));

my $summary_html = $view->report_html($qobj);

my $tidy = new HTML::Tidy;
is($tidy->parse('summary_html',$summary_html), undef, 'summary.html');
for my $message ( $tidy->messages ) {
  print $message->as_string . "\n";
}
$tidy->clear_messages();

my ($untagged) = ($summary_html =~ /^(.*untagged.*)$/m);
like($untagged, qr/999/, '999ms avg untagged nav latency');

my ($total) = ($summary_html =~ /^(.*total.*)$/m);
like($total, qr/total.*999/, '999ms avg total nav latency');
