#!/usr/bin/perl -w
#
# Test ReportLatency::StaticView.pm tag_html()
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
use Test::More tests => 12;

BEGIN { use lib '..'; }

use_ok( 'ReportLatency::Store' );
use_ok( 'ReportLatency::StaticView' );


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

isa_ok($view, 'ReportLatency::StaticView');

my $tidy = new HTML::Tidy;

my $empty_tag_html = $view->tag_html('null');
is($tidy->parse('empty_tag',$empty_tag_html), undef, 'tidy tag_html(null)');
for my $message ( $tidy->messages ) {
  print $message->as_string . "\n";
}
$tidy->clear_messages();


ok($dbh->do(q{
  INSERT INTO tag(tag,service) VALUES('Google','google.com');
}),'INSERT Google tag');
ok($dbh->do(q{
  INSERT INTO upload(location) VALUES('office.google.com');
}), 'INSERT google.com upload');
ok($dbh->do(q{
  INSERT INTO update_request(upload,name,service,count,total) VALUES(1,'google.com','google.com',3,999);
}), 'INSERT google.com request');
ok($dbh->commit,'commit');


my $tag_html = $view->tag_html('Google');
is($tidy->parse('tag',$tag_html), undef, 'tidy tag_html(Google)');

for my $message ( $tidy->messages ) {
  print $message->as_string . "\n";
}
$tidy->clear_messages();

like($tag_html, qr/333/, '333ms avg request latency found');

ok($dbh->rollback,'rollback');

