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

package ReportLatency::Store;

use strict;
use vars qw($VERSION);
use ReportLatency::utils;
use IO::String;
use URI::Escape;
use JSON;

$VERSION     = 0.1;

sub new {
  my $class = shift;
  my %p = @_;

  my $self  = bless {}, $class;

  $self->{dbh} = (defined $p{dbh} ? $p{dbh} : latency_dbh() );

  return $self;
}

sub aggregate_remote_address {
  my ($self,$remote_addr,$forwarded_for) = @_;
  my $dbh = $self->{dbh};

  $self->{location_select} =
    $dbh->prepare('SELECT rdns,location from location where ip = ?')
      unless defined $self->{location_select};
  my $ip = $forwarded_for || $remote_addr;
  my $rc = $self->{location_select}->execute($ip);
  my $row = $self->{location_select}->fetchrow_hashref;
  $self->{location_select}->finish;
  if (defined $row) {
    return $row->{location} || $row->{rdns};
  } else {
    my $location = net_class_c($ip);
    my $rdns = reverse_dns($ip);
    if ($rdns) {
      my $subdomain = $rdns;
      $subdomain =~ s/^[^.]+\.//;
      if ($subdomain) {
	$location = $subdomain;
      }
    }
    $self->{location_insert} =
      $dbh->prepare("INSERT INTO LOCATION (timestamp,ip,rdns,location)" .
		    " VALUES(DATE('now'),?,?,?)")
      unless defined $self->{location_insert};
    $self->{location_insert}->execute($ip,$rdns,$location);
    $self->{location_insert}->finish;
    return $location;
  }
}

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

sub _insert_command {
  my (@params) = @_;
  return 'INSERT INTO report (remote_addr,user_agent,' .
    join(',',@params) .
    ') VALUES(?,?' . (',?' x scalar(@params)) . ');';
}

sub _insert_post_command {
  my ($self) = @_;
  my $insert = $self->{post_insert_command};
  return $insert if defined $insert;

  my $cmd = _insert_command(@params);
  $insert = $self->{dbh}->prepare($cmd);
  return $insert;
}

sub _thank_you {
  my $self = shift;
  print <<EOF;
Content-type: text/plain
Status: 200

Thank you for your report!

EOF
}

sub _error {
  my $self = shift;
  print <<EOF;
Content-type: text/plain
Status: 500

Error occured.

EOF
  print join("\n\n",@_);
}

sub parse_www_form {
  my ($self,$q) = @_;

  my $insert = $self->_insert_post_command;
  my $dbh = $self->{dbh};

  my $remote_addr =
    $self->aggregate_remote_address($ENV{'REMOTE_ADDR'},
				    $ENV{'HTTP_X_FORWARDED_FOR'});
  my $user_agent = aggregate_user_agent($ENV{'HTTP_USER_AGENT'});
  my @insert_values;

  foreach my $p (@params) {
    my $val = $q->param($p);
    $val='' unless defined $val;
    push(@insert_values,$val);
  }

  if ($dbh->begin_work) {
    if ($insert->execute($remote_addr,$user_agent,@insert_values)) {
      if ($dbh->commit) {
	$self->_thank_you();
      } else {
	$self->_error("commit failed", $dbh->errstr);
      }
    } else {
      $self->_error("insert failed", $insert->errstr);
    }
  } else {
    $self->_error("begin_work failed", $dbh->errstr);
  }
}

sub _insert_table_hash {
  my ($self,$table,$hash) = @_;

  return "INSERT INTO $table (" .
    join(',',sort(keys %{$hash})) .
      ') VALUES (' .
	join(',', split(//,'?' x scalar(keys %{$hash}))) .
	  ');';
}

sub add_name_stats {
  my ($self,$service,$name,$location,$tz,$useragent,$version,$namestats) = @_;
  my (%sql);
  $sql{'name'} = $name if $name;
  $sql{'final_name'} = $service if $service;
  $sql{'tz'} = $tz if $tz;
  $sql{'remote_addr'} = $location if $location;
  $sql{'user_agent'} = $useragent if $useragent;
  $sql{'version'} = $version if $version;

  foreach my $stattype (qw(navigation tabupdate request)) {
    my $stat = $namestats->{$stattype};
    if (defined $stat) {
      if (ref($stat) eq 'HASH') {
	foreach my $statfield (qw(count total high low)) {
	  $sql{$stattype . '_' . $statfield} =
	    $namestats->{$stattype}->{$statfield}
	      if defined $namestats->{$stattype}->{$statfield};
	}
      }
    }
  }

  my $sql = $self->_insert_table_hash('report',\%sql);
  my $insert = $self->{dbh}->prepare($sql);
  my $rv = $insert->execute(map $sql{$_}, sort keys %sql);
  $insert->finish;
}


sub add_service_stats {
  my ($self,$location,$tz,$useragent,$version,$service,$servicestats) = @_;

  foreach my $name (keys %{$servicestats}) {
    $self->add_name_stats($service,$name,$location,$tz,$useragent,$version,
			  $servicestats->{$name});
  }
}

sub parse_json {
  my ($self,$q) = @_;

  my $json = $q->param('POSTDATA');

  my $location =
    $self->aggregate_remote_address($ENV{'REMOTE_ADDR'},
				    $ENV{'HTTP_X_FORWARDED_FOR'});
  my $user_agent = aggregate_user_agent($ENV{'HTTP_USER_AGENT'});

  my $dbh = $self->{dbh};

  my $obj;
  eval {
     $obj = decode_json $json;
  } or do {
    return $self->_error("unimplemented","parse_json()");
  };

  my $tz = $obj->{tz};
  my $version = $obj->{version};

  $dbh->begin_work or die $dbh->errstr;
  foreach my $service (keys %{$obj->{services}}) {
    $self->add_service_stats($location,$tz,$user_agent,$version,
			     $service,$obj->{services}->{$service});
  }
  $dbh->commit or return $self->_error('commit',$dbh->errstr);
  $self->_thank_you();
}

sub post {
  my ($self,$q) = @_;

  if ($q->request_method() eq 'POST') {
    my $type = $q->content_type();
    if ($type eq 'application/x-www-form-urlencoded' ||
	$type eq 'multipart/form-data') {
      return $self->parse_www_form($q);
    } elsif ($type eq 'application/json') {
      return $self->parse_json($q);
    } else {
      return $self->_error("inappropriate Content-Type ", $type);
    }
  } else {
    return $self->_error("inappropriate access method ", $q->request_method());
  }
}

sub untagged_meta_sth {
  my ($self,$start,$end) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
                  'LEFT OUTER JOIN tag ' .
                  'ON report.final_name = tag.name ' .
                  "WHERE timestamp >= datetime('now','-14 days') " .
		  'AND tag.tag IS NULL;')
      or die "prepare failed";

  return $sth;
}

sub tag_meta_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
                  'INNER JOIN tag ' .
                  'ON report.final_name = tag.name ' .
                  "WHERE timestamp >= datetime('now','-14 days') " .
		  'AND tag.tag = ?;')
      or die "prepare failed";
  return $sth;
}

sub tag_service_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
		  'INNER JOIN tag ' .
		  'ON report.final_name = tag.name ' .
                  'WHERE timestamp >= ? AND timestamp <= ? ' .
		  'AND tag.tag = ? ' .
                  'GROUP BY final_name ' .
		  'ORDER BY final_name;')
      or die "prepare failed";
  return $sth;
}

sub untagged_service_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
		  'LEFT OUTER JOIN tag ' .
		  'ON report.final_name = tag.name ' .
                  'WHERE timestamp >= ? AND timestamp <= ? ' .
		  'AND tag.tag IS NULL ' .
                  'GROUP BY final_name ' .
		  'ORDER BY final_name;')
      or die "prepare failed";
  return $sth;
}


sub service_meta_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
  return $sth;
}


sub service_select_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
  return $sth;
}


sub service_location_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
  return $sth;
}

sub summary_meta_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
  return $sth;
}


sub summary_tag_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
  return $sth;
}

sub summary_untagged_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
  return $sth;
}

sub summary_location_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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

  return $sth;
}

sub location_meta_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
  return $sth;
}


sub location_service_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
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
  return $sth;
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
