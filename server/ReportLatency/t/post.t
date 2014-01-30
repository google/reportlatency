#!/usr/bin/perl -w
#
# Test ReportLatency::Store.pm post()
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
use CGI;
use IO::String;
use File::Temp qw(tempfile tempdir);
use Test::More tests => 11;

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
		       {AutoCommit => 0}, '')
  or die $dbh->errstr;

my $store = new ReportLatency::Store(dbh => $dbh);

$ENV{'HTTP_USER_AGENT'} = 'TestAgent';
$ENV{'REMOTE_ADDR'} = '1.2.3.4';
$ENV{'REQUEST_METHOD'} = 'POST';
$ENV{'HTTP_USER_AGENT'} = $0;
$ENV{'CONTENT_TYPE'} = 'application/json';

my $postdata = new IO::String();
print $postdata <<EOF;
{"version":"1.1.0",
 "options":["default_as_org"],
 "tz":"PST",
 "services":{
   "w3.org":{
     "w3.org":{
       "request":{
         "count":4,
         "total":461.09619140625},
       "navigation":{
         "count":1,
         "total":900}}}}}
EOF
$postdata->setpos(0);
*STDIN = $postdata;

my $q = new CGI;

is($q->request_method(),'POST','request_method');


ok($store->post($q),"post()");

$q->delete_all();

my ($count) = $dbh->selectrow_array("SELECT count(*) FROM upload");
is($count, 1, '1 upload');

($count) = $dbh->selectrow_array("SELECT count(*) FROM request");
is($count, 1, '1 request entry');

($count) = $dbh->selectrow_array("SELECT count(*) FROM navigation");
is($count, 1, '1 navigation entry');


my ($timestamp,$remote_addr,$name,$service) =
  $dbh->selectrow_array("SELECT timestamp,remote_addr,name,final_name " .
			"FROM report");

like($timestamp,qr/^\d{4}-/,'timestamp');
is($remote_addr,'1.2.3.0','network address');
is($name,'w3.org','w3.org request name');
is($service,'w3.org','w3.org service name');
