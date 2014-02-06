#!/usr/bin/perl -w
#
# Test whether schema is syntactically valid
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
use Test::More tests => 10;
use File::Temp qw/ tempfile tempdir /;

my $dir = tempdir(CLEANUP => 1);

my $dbfile = "$dir/latency.sqlite";

system("sqlite3 $dbfile < sqlite3.sql");

my $tables=`sqlite3 $dbfile .tables`;
chomp($tables);
like($tables,qr/upload/,'upload table');
like($tables,qr/navigation_request/,'navigation_request table');
like($tables,qr/update_request/,'update_request table');
like($tables,qr/\snavigation\s/,'navigation table');
like($tables,qr/tag/,'tag table');
like($tables,qr/location/,'location table');
like($tables,qr/\smatch/,'match table');
like($tables,qr/notmatch/,'notmatch table');

my $before = time;
sleep 1;
system("sqlite3 $dbfile " .
       "'INSERT INTO upload(user_agent) VALUES(\"Browser\")'");
sleep 1;
my $cmd =
  "sqlite3 $dbfile 'SELECT strftime(\"%s\",timestamp) FROM upload'";
my $mtime =`$cmd`;
chomp($mtime);
my $after = time;
ok($before < $mtime,"timestamp high enough");
ok($mtime < $after,"timestamp low enough");

print "timestamp=$mtime  before=$before  after=$after\n";
