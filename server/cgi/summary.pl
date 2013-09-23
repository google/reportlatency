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
    $dbh->prepare('SELECT "total" AS tag,' .
		  'min(timestamp) AS min_timestamp,' .
                  'max(timestamp) AS max_timestamp,' .
                  'count(distinct final_name) AS services,' .
                  'sum(request_count) AS request_count,' .
                  'sum(request_total)/sum(request_count) AS request_latency,' .
                  'sum(tabupdate_count) AS tabupdate_count,' .
                  'sum(tabupdate_total)/sum(tabupdate_count) ' .
		  'AS tabupdate_latency,' .
                  'sum(navigation_count) AS navigation_count,' .
                  'sum(navigation_total)/sum(navigation_count) ' .
		  'AS navigation_latency ' .
                  'FROM report ' .
                  "WHERE timestamp >= datetime('now','-14 days');" )
      or die "prepare failed";

  my $tag_sth =
    $dbh->prepare('SELECT tag.tag as tag,' .
                  'count(distinct final_name) AS services,' .
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
		  'INNER JOIN tag ' .
		  'ON report.final_name = tag.name ' .
                  'WHERE timestamp >= ? AND timestamp <= ? ' .
                  'GROUP BY tag ' .
		  'ORDER BY tag;')
      or die "prepare failed";

  my $location_sth =
    $dbh->prepare('SELECT remote_addr,' .
                  'count(distinct final_name) AS services,' .
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
                  'GROUP BY remote_addr ' .
		  'ORDER BY remote_addr;')
      or die "prepare failed";

  my $other_sth =
    $dbh->prepare('SELECT ' .
                  'count(distinct final_name) AS services,' .
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
		  'LEFT OUTER JOIN tag ' .
		  'ON report.final_name = tag.name ' .
                  'WHERE timestamp >= ? AND timestamp <= ? ' .
		  'AND tag.tag is null;')
      or die "prepare failed";

  my $q = new CGI;

  $dbh->begin_work;

  my $rc = $meta_sth->execute();
  my $meta = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  print $q->header(-type => 'text/html');


  my $tag_header = <<EOF;
<tr>
 <th colspan=2> Tag </th>
 <th colspan=2> Request </th>
 <th colspan=2> Tab Update </th>
 <th colspan=2> Navigation </th>
</tr>
<tr>
 <th>Name</th> <th>Services</th>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
</tr>
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

<h1> ReportLatency Summary
<p align=center>
<img src="graphs/latency-spectrum.png" width="80%"
 alt="latency spectrum">
</img>
</p>

<h2> Latency By Tag </h1>

<table class="alternate">
$tag_header
<hl>
EOF

  $rc = $tag_sth->execute($meta->{'min_timestamp'},
				$meta->{'max_timestamp'});

  while (my $tag = $tag_sth->fetchrow_hashref) {
    my $name = $tag->{tag};
    my $url = "tag?name=$name";
    my $count = $tag->{'services'};
    print latency_summary_row($name,$url,$count,$tag);
  }
  $tag_sth->finish;

  $rc = $other_sth->execute($meta->{'min_timestamp'},
			    $meta->{'max_timestamp'});
  my $other = $other_sth->fetchrow_hashref;
  print latency_summary_row('untagged','untagged',$other->{'services'},$other);
  $other_sth->finish;

  print $tag_header;

  print latency_summary_row('total', '', $meta->{'services'}, $meta);

  print <<EOF;
</tr>
</table>

EOF

  my $location_header = <<EOF;
<tr>
 <th colspan=2> Location </th>
 <th colspan=2> Request </th>
 <th colspan=2> Tab Update </th>
 <th colspan=2> Navigation </th>
</tr>
<tr>
 <th>Name</th> <th>Services</th>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
 <th>Count</th> <th>Latency (ms)</th>
</tr>
EOF

  print <<EOF;
<h2> Latency By Location </h2>

<table class="alternate">
$location_header
<hl>
EOF
  $rc = $location_sth->execute($meta->{'min_timestamp'},
			       $meta->{'max_timestamp'});

  while (my $location = $location_sth->fetchrow_hashref) {
    my $name = $location->{remote_addr};
    my $url = "location?name=" . uri_escape($name);
    my $count = $location->{'services'};
    print latency_summary_row(sanitize_location($name),$url,$count,$location);
  }
  $location_sth->finish;

  $dbh->rollback;  # there shouldn't be changes

  $dbh->disconnect;

print <<EOF;
</table>

<p>
Timespan: $meta->{'min_timestamp'} through $meta->{'max_timestamp'}
</p>
                      
</body>
</html>
EOF
}

main() unless caller();
