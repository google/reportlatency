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

package ReportLatency::StaticView;

use strict;
use vars qw($VERSION);
use ReportLatency::utils;
use IO::String;
use URI::Escape;


$VERSION     = 0.1;

sub new {
  my $class = shift;
  my ($store) = @_;

  my $self  = bless {}, $class;

  $self->{store} = $store;

  return $self;
}

sub tag_img_url {
  my ($self,$tag) = @_;
  return "$tag.png";
}

sub untagged_img_url {
  return "untagged.png";
}

sub service_url_from_tag {
  my ($self,$name) = @_;
  return "../services/$name.html";
}

sub untagged_html {
  my ($self) = @_;
  my $store = $self->{store};

  my $meta_sth = $store->untagged_meta_sth;
  my $rc = $meta_sth->execute();
  my $meta = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  my $service_sth = $store->untagged_service_sth;
  $rc = $service_sth->execute($meta->{'min_timestamp'},
			      $meta->{'max_timestamp'});


  my $io = new IO::String;

  my $service_header = <<EOF;
EOF

  my $untagged_img_url = $self->untagged_img_url;

  print $io <<EOF;
<!DOCTYPE html>
<html>
<head>
  <title>Latency report for untagged services</title>
  <style type="text/css">
    table.alternate tr:nth-child(odd) td{ background-color: #CCFFCC; }
    table.alternate tr:nth-child(even) td{ background-color: #99DD99; }
  </style>
</head>
<body>

<h1> Latency Summary For Untagged Services </h1>

<p align=center>
<img src="$untagged_img_url" width="80%"
 alt="latency spectrum">
</p>

<table class="alternate" summary="Latency report for untagged services">
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
EOF

  while (my $service = $service_sth->fetchrow_hashref) {
    my $name = $service->{final_name};
    my $url = $self->service_url_from_tag($name);
    my $count = $service->{'dependencies'};
    print $io latency_summary_row($name,$url,$count,$service);
  }
  $service_sth->finish;

  print $io <<EOF;
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

  print $io latency_summary_row('total', '', $meta->{'services'}, $meta);

  print $io <<EOF;
</table>

<p>
Timespan: $meta->{'min_timestamp'} through $meta->{'max_timestamp'}
</p>
                      
</body>
</html>
EOF

  $io->setpos(0);
  return ${$io->string_ref};
}


sub summary_html {
  my ($self) = @_;
  my $dbh = $self->{dbh};

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

  my $rc = $meta_sth->execute();
  my $meta = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  my $io = new IO::String;

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

  print $io <<EOF;
<!DOCTYPE html>
<html>
<head>
  <title>ReportLatency summary</title>
  <style type="text/css">
    table.alternate tr:nth-child(odd) td{ background-color: #CCFFCC; }
    table.alternate tr:nth-child(even) td{ background-color: #99DD99; }
  </style>
</head>
<body>

<h1> ReportLatency Summary </h1>
<p align=center>
<img src="graphs/latency-spectrum.png" width="80%"
 alt="latency spectrum">
</p>

<table class="alternate" summary="Latency report for all services by tag">
$tag_header
EOF

  $rc = $tag_sth->execute($meta->{'min_timestamp'},
				$meta->{'max_timestamp'});

  while (my $tag = $tag_sth->fetchrow_hashref) {
    my $name = $tag->{tag};
    my $url = "tag?name=$name";
    my $count = $tag->{'services'};
    print $io latency_summary_row($name,$url,$count,$tag);
  }
  $tag_sth->finish;

  $rc = $other_sth->execute($meta->{'min_timestamp'},
			    $meta->{'max_timestamp'});
  my $other = $other_sth->fetchrow_hashref;
  print $io latency_summary_row('untagged','untagged',
				$other->{'services'},$other);
  $other_sth->finish;

  print $io $tag_header;

  print $io latency_summary_row('total', '', $meta->{'services'}, $meta);

  print $io <<EOF;
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

  print $io <<EOF;
<h2> Latency By Location </h2>

<table class="alternate" summary="Latency report for all services by location">
$location_header
EOF
  $rc = $location_sth->execute($meta->{'min_timestamp'},
			       $meta->{'max_timestamp'});

  while (my $location = $location_sth->fetchrow_hashref) {
    my $name = $location->{remote_addr};
    my $url = "location?name=" . uri_escape($name);
    my $count = $location->{'services'};
    print $io latency_summary_row(sanitize_location($name),$url,
				  $count,$location);
  }
  $location_sth->finish;

print $io <<EOF;
</table>

<p>
Timespan: $meta->{'min_timestamp'} through $meta->{'max_timestamp'}
</p>
                      
</body>
</html>
EOF

  $io->setpos(0);
  return ${$io->string_ref};
}

sub location_html {
  my ($self,$loc) = @_;
  my $dbh = $self->{dbh};

  my $unescape = uri_unescape($loc);
  my $location = sanitize_location($unescape);

  my $io = new IO::String;

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


  my $rc = $meta_sth->execute($location);
  my $meta = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  my $service_header = <<EOF;
EOF

  print $io <<EOF;
<!DOCTYPE html>
<html>
<head>
  <title>Latency Summary For Location $location</title>
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
</p>

<table class="alternate" summary="Latency report for all services at location $location">
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
EOF

  $rc = $service_sth->execute($meta->{'min_timestamp'},
			      $meta->{'max_timestamp'},$location);

  while (my $service = $service_sth->fetchrow_hashref) {
    my $name = sanitize_service($service->{final_name});
    if (defined $name) {
      my $url = "service?service=$name";
      my $count = $service->{'dependencies'};
      print $io latency_summary_row($name,$url,$count,$service);
    }
  }
  $service_sth->finish;

  print $io <<EOF;
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

  print $io latency_summary_row('total', '', $meta->{'services'}, $meta);

  print $io <<EOF;
</table>

<p>
Timespan: $meta->{'min_timestamp'} through $meta->{'max_timestamp'}
</p>
                      
</body>
</html>
EOF

  $io->setpos(0);
  return ${$io->string_ref};
}


sub service_img_url {
  my ($self,$service) = @_;

  return "$service.png";
}

sub service_not_found($$) {
  my ($self,$name) = @_;

  my $io = new IO::String;

  print $io <<EOF;
<!DOCTYPE html>
<html>
<body>
<h1> Latency Report </h1>

No recent reports were found for $name
</body>
</html>
EOF
  $io->setpos(0);
  return ${$io->string_ref};
}

sub service_found {
  my ($self,$service,$meta,$select,$select_location) = @_;

  my $io = new IO::String;

  my $rc = $select->execute($service);

  my $service_img_url = $self->service_img_url($service);

  print $io <<EOF;
<!DOCTYPE html>
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
<img src="$service_img_url" width="80%" alt="latency spectrum">
</p>

<h2> All locations, each request name </h2>

<table class="alternate" summary="$service latency by request name">
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
EOF

  while ( my $row = $select->fetchrow_hashref) {
    my $name = sanitize_service($row->{'name'}) or next;
    print $io "  <tr>";
    print $io " <td> $name </td>";
    print $io " <td align=right> " . mynum($row->{'request_count'}) . " </td>";
    print $io " <td align=right> " . myround($row->{'request_latency'}) . " </td>";
    print $io " <td align=right> " . mynum($row->{'tabupdate_count'}) . " </td>";
    print $io " <td align=right> " . myround($row->{'tabupdate_latency'}) . " </td>";
    print $io " <td align=right> " . mynum($row->{'navigation_count'}) . " </td>";
    print $io ' <td align=right> ' .
      myround($row->{'navigation_latency'}) . " </td>";
    print $io "  </tr>\n";
  }

  $select->finish;

  print $io <<EOF;
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
  print $io "  <td align=right> " . mynum($meta->{'request_count'}) .
    " </td>\n";
  print $io "  <td align=right> " .
    average($meta->{'request_total'},$meta->{'request_count'}) .
      " </td>\n";
  print $io "  <td align=right> " . mynum($meta->{'tabupdate_count'}) .
    " </td>\n";
  print $io "  <td align=right> " .
    average($meta->{'tabupdate_total'},$meta->{'tabupdate_count'}) .
      " </td>\n";
  print $io "  <td align=right> " . mynum($meta->{'navigation_count'}) .
    " </td>\n";
  print $io "  <td align=right> " .
    average($meta->{'navigation_total'},$meta->{'navigation_count'}) .
      " </td>\n";

  print $io <<EOF;
</tr>
</table>

<h2> Each location, names aggregated </h2>

<table class="alternate" summary="$service latency by location">
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
EOF

  $rc = $select_location->execute($service);

  while ( my $row = $select_location->fetchrow_hashref) {
    print $io "  <tr>";
    print $io " <td> " . $row->{'remote_addr'} . " </td>";
    print $io " <td align=right> " . mynum($row->{'request_count'}) . " </td>";
    print $io " <td align=right> " . myround($row->{'request_latency'}) . " </td>";
    print $io " <td align=right> " . mynum($row->{'tabupdate_count'}) . " </td>";
    print $io " <td align=right> " . myround($row->{'tabupdate_latency'}) . " </td>";
    print $io " <td align=right> " . mynum($row->{'navigation_count'}) . " </td>";
    print $io ' <td align=right> ' .
      myround($row->{'navigation_latency'}) . " </td>";
    print $io "  </tr>\n";
  }

  $select->finish;

  print $io <<EOF;
</table>
<p>
Timespan: $meta->{'min_timestamp'} through $meta->{'max_timestamp'}
</p>

</body>
</html>
EOF

  $io->setpos(0);
  return ${$io->string_ref};
}

sub service_html {
  my ($self,$svc) = @_;
  my $store = $self->{store};
  my $dbh = $store->{dbh};

  my $service_name = sanitize_service($svc);

  my $io = new IO::String;

  my $meta_sth = $store->service_meta_sth;
  my $select_sth = $store->service_select_sth;
  my $select_location_sth = $store->service_location_sth;


  my $rc = $meta_sth->execute($service_name);
  my $row = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  if (!defined $row) {
    return $self->service_not_found($service_name);
  } else {
    return $self->service_found($service_name,$row,$select_sth,$select_location_sth);
  }
}

sub tag_html {
  my ($self,$tag) = @_;
  my $store = $self->{store};

  my $tag_name = sanitize($tag);
  my $tag_img_url = $self->tag_img_url($tag_name);

  my $meta_sth = $store->tag_meta_sth;
  my $service_sth = $store->tag_service_sth;


  my $rc = $meta_sth->execute($tag);
  my $meta = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  my $io = new IO::String;

  my $service_header = <<EOF;
EOF

  print $io <<EOF;
<!DOCTYPE html>
<html>
<head>
  <title>$tag_name ReportLatency summary</title>
  <style type="text/css">
    table.alternate tr:nth-child(odd) td{ background-color: #CCFFCC; }
    table.alternate tr:nth-child(even) td{ background-color: #99DD99; }
  </style>
</head>
<body>

<h1> Latency Summary For Tag $tag_name </h1>

<p align=center>
<img src="$tag_img_url" width="80%"
 alt="latency spectrum">
</p>

<table class="alternate" summary="Latency report for $tag_name services">
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
EOF

  $rc = $service_sth->execute($meta->{'min_timestamp'},
			      $meta->{'max_timestamp'},$tag_name);

  while (my $service = $service_sth->fetchrow_hashref) {
    my $name = sanitize_service($service->{final_name});
    if (defined $name) {
      my $url = "service?service=$name";
      my $count = $service->{'dependencies'};
      print $io latency_summary_row(sanitize_service($name),$url,$count,
				    $service);
    }
  }
  $service_sth->finish;

  print $io <<EOF;
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

  print $io latency_summary_row('total', '', $meta->{'services'}, $meta);

  print $io <<EOF;
</table>

<p>
Timespan: $meta->{'min_timestamp'} through $meta->{'max_timestamp'}
</p>
                      
</body>
</html>
EOF
  $io->setpos(0);
  return ${$io->string_ref};
}

1;


=pod

==head1 NAME

ReportLatency::Store - Storage object for ReportLatency data

=head1 VERSION

version 0.1

=head1 SYNOPSIS

use LatencyReport::Store

$store = new LatencyReport::Store(
  dbh => $dbh
);

=head1 DESCRIPTION

LatencyReport::Store accepts reports and produces measurements for
table and spectrum generation.  The storage is in a database,
typically sqlite3 or syntactically compatible.

=head1 USAGE

=head2 Methods

=head3 Constructors

=over 4
=item * LatencyReport::Store->new(...)

=over 8

=item * dbh

The database handle for the sqlite3 or compatible database that should
be used for real storage by this object.  The schema must already be present.

=head3 Member functions

=over 4
=item * post(CGI)
=over 8
  Parse a CGI request object for latency report data and
  insert it into the database.

=head1 KNOWN BUGS

=head1 SUPPORT

=head1 SEE ALSO

=head1 AUTHOR

Drake Diedrich <dld@google.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright Google Inc.  All Rights Reserved.

This is free software, licensed under:

  The Apache 2.0 License

=cut
