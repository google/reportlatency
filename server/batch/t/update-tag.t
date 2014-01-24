#!/usr/bin/perl -w
#
# Test udpate-tag.sql
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
use Test::More tests => 5;
use File::Temp qw(tempfile tempdir);

$ENV{'PATH'} = '/usr/bin';

BEGIN { use lib ".."; }

my $dir = tempdir(CLEANUP => 1);
mkdir("$dir/data");
my $dbfile="$dir/data/latency.sqlite3";

# laod schema
{
  open(my $sqlite3,"|-",'sqlite3',$dbfile) or die $!;
  open(my $sql,'<','../sql/sqlite3.sql') or die $!;
  while (my $line = $sql->getline) {
    print $sqlite3 $line;
  }
  close($sql);
  ok(close($sqlite3),'latency schema');
}

# preload some data
{
  open(my $sqlite3,"|-",'sqlite3',$dbfile)
    or die $!;
  print $sqlite3 <<EOF;
INSERT INTO match(tag,re) VALUES('Company','%.company.com');
INSERT INTO request(name) VALUES('host.company.com');
EOF

  ok(close($sqlite3),"request data added");
}

# update tags (the thing to really test)
{
  open(my $sqlite3,"|-",'sqlite3',$dbfile)
    or die $!;
  open(my $sql,'<','update-tag.sql') or die $!;
  while (my $line = $sql->getline) {
    print $sqlite3 $line;
  }
  close($sql);
  ok(close($sqlite3),"update-tag.sql run");
}

# verify some results
my $dbh;
$dbh = DBI->connect("dbi:SQLite:dbname=$dbfile",
                       {AutoCommit => 0}, '')
  or die $dbh->errstr;

my $count_sth = $dbh->prepare("SELECT count(*) FROM tag");
$count_sth->execute();
my ($count) = $count_sth->fetchrow_array;
is($count, 1, '1 tag');
$count_sth->finish;


chdir($dir);


unlink($dbfile);
rmdir("$dir/data");
ok(rmdir($dir),"rmdir tmpdir");

