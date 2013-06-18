#!/usr/bin/perl -wT
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

use JSON::RPC::Server::CGI;
use DBI;
use ReportLatency::utils;
use ReportLatency::Store;
use strict;

sub main {
  my $dbh = latency_dbh();
  my $store = new ReportLatency::Store(dbh => $dbh);

  my $q = CGI->new;
                                                                
  my $remote_addr =
    $store->aggregate_remote_address($ENV{'REMOTE_ADDR'},
				     $ENV{'HTTP_X_FORWARDED_FOR'});
  my $user_agent = aggregate_user_agent($ENV{'HTTP_USER_AGENT'});

  $dbh->disconnect;

  print <<EOF;
Content-type: text/plain

Thank you for your report!

EOF
}

main() unless caller();
