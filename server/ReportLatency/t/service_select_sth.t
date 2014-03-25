#!/usr/bin/perl -w
#
# Test ReportLatency::Store.pm.pm's service_select_sth()
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
use Data::Dumper;

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
$dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", {}, '')
  or die $dbh->errstr;

my $store = new ReportLatency::Store(dbh => $dbh);


ok($dbh->do(q{
  INSERT INTO upload(location) VALUES("1.2.3.0");
}), 'INSERT upload');
ok($dbh->do(q{
  INSERT INTO navigation(upload,name,service,count,total)
    VALUES(1,'mail.google.com','mail.google.com',1,2038);
}), 'INSERT mail.google.com navigation');
ok($dbh->do(q{
  INSERT INTO navigation_request(upload,name,service,count,total)
    VALUES(1,'mail.google.com','mail.google.com',1,1492);
}), 'INSERT mail.google.com update_request');
ok($dbh->do(q{
  INSERT INTO upload(location) VALUES("1.2.3.0");
}), 'INSERT upload');
ok($dbh->do(q{
  INSERT INTO update_request(upload,name,service,count,total)
    VALUES(2,'mail.google.com','mail.google.com',10,2220);
}), 'INSERT mail.google.com update_request');
ok($dbh->do(q{
  INSERT INTO upload(location) VALUES("1.2.3.0");
}), 'INSERT upload');
ok($dbh->do(q{
  INSERT INTO update_request(upload,name,service,count,total)
    VALUES(3,'news.google.com','news.google.com',10,3330);
}), 'INSERT news.google.com update_request');


my $sth = $store->service_select_sth();
$sth->execute('mail.google.com');

my $rows = 0;
while (my $row = $sth->fetchrow_hashref) {
  print STDERR Dumper($row);
  is_deeply($row,
	    {
	     request_count => 10,
	     request_latency => 222,
	     navigation_count => 1,
	     navigation_latency => 2038,
	     name => 'mail.google.com'
	    },
	    'mail.google.com data row');
  $rows++;
}
is($rows, 1, "1 row for mail.google.com");
