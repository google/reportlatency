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

use DBI;
use CGI;
use ReportLatency::utils;
use ReportLatency::Store;
use strict;

# process these form parameters and insert into same table columns
my @params = qw( name final_name tz
                 tabupdate_count tabupdate_total
                 tabupdate_high tabupdate_low
                 request_count request_total
		 request_high request_low
                 navigation_count navigation_total
                 navigation_high navigation_low
                 navigation_committed_total navigation_committed_count
                 navigation_committed_high
              );


sub aggregate_user_agent($) {
  my ($browser) = @_;

  if ($browser =~ /Chrome\//) {
    return "Chrome";
  }

  if ($browser =~ /(Firefox|Gecko\/)/) {
    return "Firefox";
  }

  if ($browser =~ /Safari\//) {
    return "Safari";
  }

  if ($browser =~ /IE/) {
    return "IE";
  }

  return "Other";
}

sub insert_command {
  my (@params) = @_;
  return 'INSERT INTO report (remote_addr,user_agent,' .
    join(',',@params) .
    ') VALUES(?,?' . (',?' x scalar(@params)) . ');';
}



sub main {
  my $dbh = latency_dbh();
  my $store = new ReportLatency::Store(dbh => $dbh);

  my $cmd = insert_command(@params);
  my $insert = $dbh->prepare($cmd);

  my $q = CGI->new;
                                                                
  my $remote_addr =
    $store->aggregate_remote_address($ENV{'REMOTE_ADDR'},
				     $ENV{'HTTP_X_FORWARDED_FOR'});
  my $user_agent = aggregate_user_agent($ENV{'HTTP_USER_AGENT'});
  my @insert_values;

  foreach my $p (@params) {
    my $val = $q->param($p);
    $val='' unless defined $val;
    push(@insert_values,$val);
  }

  my $rc = $insert->execute($remote_addr,$user_agent,@insert_values);
  $insert->finish;
  $dbh->disconnect;

  print <<EOF;
Content-type: text/plain

Thank you for your report!

EOF
}

main() unless caller();
