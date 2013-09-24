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
use URI::Escape;

use strict;


sub main {
  my $dbh = latency_dbh('backup');

  my $meta_sth =
    $dbh->prepare('SELECT count(distinct final_name) AS services,' .
		  'min(timestamp) AS min_timestamp,' .
                  'max(timestamp) AS max_timestamp,' .
                  'sum(tabupdate_count) AS tabupdate_count,' .
                  'sum(tabupdate_total)/sum(tabupdate_count)' .
                  ' AS tabupdate_latency,' .
                  'sum(request_count) AS request_count,' .
                  'sum(request_total)/sum(request_count)' .
                  ' AS request_latency,' .
                  'sum(navigation_count) AS navigation_count,' .
                  'sum(navigation_total)/sum(navigation_count)' .
                  ' AS navigation_latency ' .
                  'FROM report ' .
                  "WHERE timestamp >= datetime('now','-14 days') " .
		  'AND remote_addr = ?;')
      or die "prepare failed";


  my $service_sth =
    $dbh->prepare('SELECT final_name,' .
                  'count(distinct report.name) AS dependencies,' .
                  'sum(tabupdate_count) AS tabupdate_count,' .
                  'sum(tabupdate_total)/sum(tabupdate_count)' .
                  ' AS tabupdate_latency,' .
                  'sum(request_count) AS request_count,' .
                  'sum(request_total)/sum(request_count)' .
                  ' AS request_latency,' .
                  'sum(navigation_count) AS navigation_count,' .
                  'sum(navigation_total)/sum(navigation_count)' .
                  ' AS navigation_latency ' .
                  'FROM report ' .
                  'WHERE timestamp >= ? AND timestamp <= ? ' .
		  'AND remote_addr = ? ' .
                  'GROUP BY final_name ' .
		  'ORDER BY final_name;')
      or die "prepare failed";

  my $q = new CGI;
  my $unescape = uri_unescape($q->param('name'));
  my $location = sanitize_location($unescape);

  print STDERR "name=" . $q->param('name') . "\n";
  print STDERR "unescape=$unescape\n";
  print STDERR "location=$location\n";

  $dbh->begin_work;

  my $rc = $meta_sth->execute($location);
  my $meta = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  print $q->header(-type => 'text/html');

  my $service_header = <<EOF;
EOF

  print <<EOF;
<html>
<head>
  <style type="text/css">
    table.alternate tr:nth-child(odd) td{ background-color: #CCFFCC; }
    table.alternate tr:nth-child(even) td{ background-color: #99DD99; }
  </style>
</head>
<body>

<h1> Latency Summary For Location $location </h1>

<p align=center>
<img src="graphs/location/$location.png" width="80%"
 alt="latency spectrum">
</img>
</p>

<table class="alternate">
<tr>
 <th colspan=2> Service </th>
 <th colspan=2> Request </th>
 <th colspan=2> Tab Update </th>
 <th colspan=2> Navigation </th>
</tr>
<tr>
 <th>Name</th> <th>Dependencies</th>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
</tr>
<hl>
EOF

  $rc = $service_sth->execute($meta->{'min_timestamp'},
			      $meta->{'max_timestamp'},$location);

  while (my $service = $service_sth->fetchrow_hashref) {
    my $name = sanitize_service($service->{final_name});
    if (defined $name) {
      my $url = "service?service=$name";
      my $count = $service->{'dependencies'};
      print latency_summary_row($name,$url,$count,$service);
    }
  }
  $service_sth->finish;

  $dbh->rollback;  # there shouldn't be changes

  $dbh->disconnect;

  print <<EOF;
<tr>
 <th> Service </th>
 <th> Service </th>
 <th colspan=2> Request </th>
 <th colspan=2> Tab Update </th>
 <th colspan=2> Navigation </th>
</tr>
<tr>
 <th></th> <th>Count</th>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
</tr>
EOF

  print latency_summary_row('total', '', $meta->{'services'}, $meta);

  print <<EOF;
</tr>
</table>

<p>
Timespan: $meta->{'min_timestamp'} through $meta->{'max_timestamp'}
</p>
                      
</body>
</html>
EOF
}

main() unless caller();
