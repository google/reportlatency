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


sub service_not_found($$) {
  my ($q,$name) = @_;

  print $q->header(-type => 'text/html');

  print <<EOF;
<html>
<body>
<h1> Latency Report </h1>

No recent reports were found for $name
</body>
</html>
EOF
}

sub service_found($$$$$) {
  my ($q,$service,$meta,$select,$select_location) = @_;

  my $rc = $select->execute($service);

  print $q->header(-type => 'text/html');

  print <<EOF;
<html>
<head>
  <style type="text/css">
    table.alternate tr:nth-child(odd) td{ background-color: #CCFFCC; }
    table.alternate tr:nth-child(even) td{ background-color: #99DD99; }
  </style>
  <title> $meta->{'date'} $service Latency </title>
</head>
<body>

<h1> $service $meta->{'date'} Latency Report </h1>

<p align=center>
<img src="graphs/service/$service.png" width="80%" alt="latency spectrum">
</img>
</p>

<h2> All locations, each name </h2>

<table class="alternate">
<tr>
 <th rowspan=2> Request Name</th>
 <th colspan=2> Request </th>
 <th colspan=2> Tab Update </th>
 <th colspan=2> Navigation </th>
</tr>
<tr>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
</tr>
<hl>
EOF

  while ( my $row = $select->fetchrow_hashref) {
    my $name = sanitize_service($row->{'name'}) or next;
    print "  <tr>";
    print " <td> $name </td>";
    print " <td align=right> " . mynum($row->{'request_count'}) . " </td>";
    print " <td align=right> " . myround($row->{'request_latency'}) . " </td>";
    print " <td align=right> " . mynum($row->{'tabupdate_count'}) . " </td>";
    print " <td align=right> " . myround($row->{'tabupdate_latency'}) . " </td>";
    print " <td align=right> " . mynum($row->{'navigation_count'}) . " </td>";
    print ' <td align=right> ' .
      myround($row->{'navigation_latency'}) . " </a></td>";
    print "  </tr>\n";
  }

  $select->finish;

  print <<EOF;
<tr>
 <th rowspan=2> Request Name</th>
 <th colspan=2> Request </th>
 <th colspan=2> Tab Update </th>
 <th colspan=2> Navigation </th>
</tr>
<tr>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
</tr>
<tr> <td align=center> total </td>
EOF
  print "  <td align=right> " . mynum($meta->{'request_count'}) .
    " </td>\n";
  print "  <td align=right> " .
    average($meta->{'request_total'},$meta->{'request_count'}) .
      " </td>\n";
  print "  <td align=right> " . mynum($meta->{'tabupdate_count'}) .
    " </td>\n";
  print "  <td align=right> " .
    average($meta->{'tabupdate_total'},$meta->{'tabupdate_count'}) .
      " </td>\n";
  print "  <td align=right> " . mynum($meta->{'navigation_count'}) .
    " </td>\n";
  print "  <td align=right> " .
    average($meta->{'navigation_total'},$meta->{'navigation_count'}) .
      " </td>\n";

  print <<EOF;
</tr>
</table>

<h2> Each location, names aggregated </h2>

<table class="alternate">
<tr>
 <th rowspan=2> Location </th>
 <th colspan=2> Request </th>
 <th colspan=2> Tab Update </th>
 <th colspan=2> Navigation </th>
</tr>
<tr>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
</tr>
<hl>
EOF

  $rc = $select_location->execute($service);

  while ( my $row = $select_location->fetchrow_hashref) {
    print "  <tr>";
    print " <td> " . $row->{'remote_addr'} . " </td>";
    print " <td align=right> " . mynum($row->{'request_count'}) . " </td>";
    print " <td align=right> " . myround($row->{'request_latency'}) . " </td>";
    print " <td align=right> " . mynum($row->{'tabupdate_count'}) . " </td>";
    print " <td align=right> " . myround($row->{'tabupdate_latency'}) . " </td>";
    print " <td align=right> " . mynum($row->{'navigation_count'}) . " </td>";
    print ' <td align=right> ' .
      myround($row->{'navigation_latency'}) . " </a></td>";
    print "  </tr>\n";
  }

  $select->finish;

  print <<EOF;
<p>
Timespan: $meta->{'min_timestamp'} through $meta->{'max_timestamp'}
</p>

</body>
</html>
EOF
}

sub main {
  my $dbh = latency_dbh();

  my $meta_sth =
    $dbh->prepare('SELECT final_name,' .
		  'min(timestamp) AS min_timestamp,' .
                  'max(timestamp) AS max_timestamp,' .
		  "DATE('now') as date," .
                  'sum(tabupdate_count) AS tabupdate_count,' .
                  'sum(tabupdate_total) AS tabupdate_total,' .
                  'sum(request_count) AS request_count,' .
                  'sum(request_total) AS request_total,' .
                  'sum(navigation_count) AS navigation_count,' .
                  'sum(navigation_total) AS navigation_total ' .
		  'FROM report ' .
                  'WHERE final_name=? AND ' .
		  "timestamp >= DATETIME('now','-14 days');")
      or die "prepare failed";

  my $select_sth =
    $dbh->prepare('SELECT name,' .
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
                  'WHERE final_name=? AND ' .
		  "timestamp >= DATETIME('now','-14 days') " .
                  'GROUP BY name ' .
		  'ORDER BY name;')
      or die "prepare failed";

  my $select_location_sth =
    $dbh->prepare('SELECT remote_addr,' .
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
                  'WHERE final_name=? AND ' .
		  "timestamp >= DATETIME('now','-14 days') " .
                  'GROUP BY remote_addr ' .
		  'ORDER BY remote_addr;')
      or die "prepare failed";

  my $q = new CGI;
  my $service_name = sanitize_service($q->param('service'));

  $dbh->begin_work;

  my $rc = $meta_sth->execute($service_name);
  my $row = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  if (!defined $row) {
    service_not_found($q,$service_name);
  } else {
    service_found($q,$service_name,$row,$select_sth,$select_location_sth);
  }

  $dbh->rollback;  # there shouldn't be changes

  $dbh->disconnect;
}

main() unless caller();
