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
use Test::More tests => 9;
use HTML::Tidy;

BEGIN { unshift(@INC,'.'); use_ok( 'ReportLatency::Store' ); }


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

my $store = new ReportLatency::Store(dbh => $dbh);

isa_ok($store, 'ReportLatency::Store');

is($store->{dbh}, $dbh, "dbh");

is($store->aggregate_remote_address('8.8.8.8'),'google.com.',
   'aggregate_remote_address(8.8.8.8)');
is($store->aggregate_remote_address('8.8.8.8'),'google.com.',
   '2nd aggregate_remote_address(8.8.8.8)');
is($store->aggregate_remote_address('0.0.0.1'),'0.0.0.0',
   'aggregate_remote_address(0.0.0.1)');


is(ReportLatency::Store::_insert_command('name','value'),
   'INSERT INTO report (remote_addr,user_agent,name,value) VALUES(?,?,?,?);',
   'insert_command()');


my $tidy = new HTML::Tidy;

my $empty_tag_html = $store->tag_html('null');
ok($tidy->parse('empty_tag',$empty_tag_html),'tag_html(null) is tidy');
