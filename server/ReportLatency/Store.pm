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
use vars qw($VERSION %options);
use ReportLatency::utils;
use IO::String;
use URI::Escape;
use JSON;
use Data::Dumper;

$VERSION     = 0.1;
%options = ();

require ReportLatency::data;


sub new {
  my $class = shift;
  my %p = @_;

  my $self  = bless {}, $class;

  $self->{dbh} = (defined $p{dbh} ? $p{dbh} : latency_dbh() );

  return $self;
}

sub register_option {
  my ($opt,$mask) = @_;
  $options{$opt} = $mask;
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

sub _insert_table_hash {
  my ($self,$table,$hash) = @_;

  return "INSERT INTO $table (" .
    join(',',sort(keys %{$hash})) .
      ') VALUES (' .
	join(',', split(//,'?' x scalar(keys %{$hash}))) .
	  ');';
}

sub option_bits {
  my ($self,$options) = @_;
  return undef unless defined $options;

  my $bits = 0;
  foreach my $opt (@{$options}) {
    if ($ReportLatency::Store::options{$opt}) {
      $bits |= $ReportLatency::Store::options{$opt};
    }
  }
  return $bits;
}

sub add_request_stats {
  my ($self,$upload_id, $service, $name, $requeststats) = @_;

  $self->{insert_requests} =
    $self->{dbh}->prepare("INSERT INTO request " .
			  "(upload, service, name, count, total, high, low) " .
			  "VALUES(?,?,?,?,?,?,?);")
      unless defined $self->{insert_requests};

  $self->{insert_requests}->execute($upload_id, $service, $name,
				    $requeststats->{'count'},
				    $requeststats->{'total'},
				    $requeststats->{'high'},
				    $requeststats->{'low'});
}

sub add_navigation_stats {
  my ($self,$upload_id, $service, $name, $navstats) = @_;

  $self->{insert_navigations} =
    $self->{dbh}->prepare("INSERT INTO navigation " .
			  "(upload, service, name, count, total, high, low) " .
			  "VALUES(?,?,?,?,?,?,?);")
      unless defined $self->{insert_navigations};

  $self->{insert_navigations}->execute($upload_id, $service, $name,
					$navstats->{'count'},
					$navstats->{'total'},
					$navstats->{'high'},
					$navstats->{'low'});
}


sub add_name_stats {
  my ($self,$upload_id, $service, $name, $namestats) = @_;

  if (defined $namestats->{'request'}) {
    $self->add_request_stats($upload_id, $service, $name,
			     $namestats->{'request'});
  }
  if (defined $namestats->{'navigation'}) {
    $self->add_navigation_stats($upload_id, $service, $name,
				$namestats->{'navigation'});
  }
}


sub add_service_stats {
  my ($self,$upload_id, $service, $servicestats) = @_;

  foreach my $name (keys %{$servicestats}) {
    $self->add_name_stats($upload_id,$service, $name, $servicestats->{$name});
  }
}

sub new_upload {
  my ($self,$obj) = @_;

  $self->{upload_insert} =
    $self->{dbh}->prepare("INSERT INTO upload " .
		  "(collected_on,location,user_agent,tz,version,options)" .
		  " VALUES(?,?,?,?,?,?)")
      unless defined $self->{upload_insert};

  if (! defined $self->{hostname}) {
    $self->{hostname} = $ENV{HTTP_HOST} || $ENV{SERVER_ADDR};
  }

  my $upload_sth =
    $self->{upload_insert}->execute($self->{hostname}, $obj->{location},
				    $obj->{user_agent}, $obj->{tz},
				    $obj->{version},
				    $obj->{options});
#  $upload_sth->finish();

  my ($lastval) = $self->{dbh}->selectrow_array("SELECT last_insert_rowid()");

  return $lastval;
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

  my $options = $self->option_bits($obj->{options});
  $obj->{options} = $options;
  $obj->{location} = $location;
  $obj->{user_agent} = $user_agent;

  $dbh->begin_work or die $dbh->errstr;

  my $upload_id = $self->new_upload($obj);

  foreach my $service (keys %{$obj->{services}}) {
    $self->add_service_stats($upload_id, $service,
			     $obj->{services}->{$service});
  }
  $dbh->commit or return $self->_error('commit',$dbh->errstr);
  $self->_thank_you();
}

sub post {
  my ($self,$q) = @_;

  if ($q->request_method() eq 'POST') {
    my $type = $q->content_type();
    if ($type eq 'application/json') {
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
