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

sub insert_stats {
  my ($self, $insert, $upload_id, $service, $name, $stats) = @_;
  my ($r200,$r300,$r400,$r500);

  if (defined $stats->{"response"}) {
    my ($key,$val);
    while ( ($key,$val) = each %{$stats->{"response"}}) {
      if ($key >= 200 && $key < 300) {
	$r200 += $val;
      } elsif ($key >= 300 && $key < 400) {
	$r300 += $val;
      } elsif ($key >= 400 && $key < 500) {
	$r400 += $val;
      } elsif ($key >= 500 && $key < 600) {
	$r500 += $val;
      }
    }
  }

  $insert->execute($upload_id, $service, $name,
		   $stats->{'count'},
		   $stats->{'total'},
		   $stats->{'high'},
		   $stats->{'low'},
		   $stats->{'tabclosed'}, $r200, $r300, $r400, $r500);
}

sub add_navigation_request_stats {
  my ($self,$upload_id, $service, $name, $requeststats) = @_;

  $self->{insert_navigation_requests} =
    $self->{dbh}->prepare("INSERT INTO navigation_request " .
			  "(upload, service, name, count, total, high, low, " .
			  "tabclosed, response200, response300, " .
			  "response400, response500) " .
			  "VALUES(?,?,?,?,?,?,?,?,?,?,?,?);")
      unless defined $self->{insert_navigation_requests};

  $self->insert_stats($self->{insert_navigation_requests},
		      $upload_id, $service, $name, $requeststats);
}

sub add_update_request_stats {
  my ($self,$upload_id, $service, $name, $requeststats) = @_;

  $self->{insert_update_requests} =
    $self->{dbh}->prepare("INSERT INTO update_request " .
			  "(upload, service, name, count, total, high, low, " .
			  "tabclosed, response200, response300, " .
			  "response400, response500 ) " .
			  "VALUES(?,?,?,?,?,?,?,?,?,?,?,?);")
      unless defined $self->{insert_update_requests};

  $self->insert_stats($self->{insert_update_requests},
		      $upload_id, $service, $name, $requeststats);
}

sub add_navigation_stats {
  my ($self,$upload_id, $service, $name, $navstats) = @_;

  $self->{insert_navigations} =
    $self->{dbh}->prepare("INSERT INTO navigation " .
			  "(upload, service, name, count, total, high, low, " .
			  "tabclosed) " .
			  "VALUES(?,?,?,?,?,?,?,?);")
      unless defined $self->{insert_navigations};

  $self->{insert_navigations}->execute($upload_id, $service, $name,
				       $navstats->{'count'},
				       $navstats->{'total'},
				       $navstats->{'high'},
				       $navstats->{'low'},
				       $navstats->{'tabclosed'});
}


sub add_name_stats {
  my ($self,$upload_id, $service, $name, $namestats) = @_;

  if (defined $namestats->{'nreq'}) {
    $self->add_navigation_request_stats($upload_id, $service, $name,
					$namestats->{'nreq'});
  } 
  if (defined $namestats->{'request'}) { # older extension.  delete soon.
    $self->add_navigation_request_stats($upload_id, $service, $name,
					$namestats->{'request'});
  }
  if (defined $namestats->{'ureq'}) {
    $self->add_update_request_stats($upload_id, $service, $name,
				    $namestats->{'ureq'});
  }
  if (defined $namestats->{'nav'}) {
    $self->add_navigation_stats($upload_id, $service, $name,
				$namestats->{'nav'});
  }
  if (defined $namestats->{'navigation'}) { # older extension. delete soon.
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
    $self->{hostname} = $ENV{SSL_SERVER_S_DN_CN} ||
      $ENV{SERVER_ADDR} || $ENV{SERVER_NAME} || $ENV{HTTP_HOST};
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
    $dbh->prepare('SELECT count(distinct r.service) AS services,' .
		  'min(r.timestamp) AS min_timestamp,' .
                  'max(r.timestamp) AS max_timestamp,' .
		  $self->common_aggregate_fields() .
                  ' FROM report AS r ' .
                  'LEFT OUTER JOIN tag ' .
                  'ON r.service = tag.service ' .
                  "WHERE r.timestamp >= datetime('now','-14 days') " .
		  'AND tag.tag IS NULL;')
      or die "prepare failed";

  return $sth;
}

sub tag_nav_latencies_sth {
  my ($self) = @_;

  my $sth = $self->{tag_nav_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT strftime("%s",r.timestamp) AS timestamp,' .
      'r.navigation_count AS count,' .
      'r.navigation_high AS high,' .
      'r.navigation_low AS low,' .
      'r.navigation_total AS total ' .
      'FROM oldreport AS r ' .
       'INNER JOIN tag ON r.final_name = tag.service ' .
       "WHERE r.timestamp <= datetime('now',?) AND " .
       "r.timestamp > datetime('now',?) AND " .
       'tag.tag = ? AND ' .
       "r.navigation_count IS NOT NULL AND r.navigation_count != '' AND " .
       "r.navigation_count>0;";
    $sth = $dbh->prepare($statement) or die $!;
  }

  return $sth;
}

sub tag_meta_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT count(distinct r.service) AS services,' .
		  'min(r.timestamp) AS min_timestamp,' .
                  'max(r.timestamp) AS max_timestamp,' .
		  $self->common_aggregate_fields() .
                  ' FROM report AS r ' .
                  'INNER JOIN tag ' .
                  'ON r.service = tag.service ' .
                  "WHERE r.timestamp >= datetime('now','-14 days') " .
		  'AND tag.tag = ?;')
      or die "prepare failed";
  return $sth;
}

sub tag_service_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT r.service AS service,' .
                  'count(distinct r.name) AS dependencies,' .
		  $self->common_aggregate_fields() .
                  ' FROM report AS r ' .
		  'INNER JOIN tag ' .
		  'ON r.service = tag.service ' .
                  'WHERE r.timestamp >= ? AND r.timestamp <= ? ' .
		  'AND tag.tag = ? ' .
                  'GROUP BY r.service ' .
		  'ORDER BY r.service;')
      or die "prepare failed";
  return $sth;
}

sub untagged_service_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT r.final_name AS service,' .
                  'count(distinct r.name) AS dependencies,' .
                  'sum(r.request_count) AS request_count,' .
                  'sum(r.request_total)/sum(r.request_count)' .
                  ' AS request_latency,' .
                  'sum(r.navigation_count) AS navigation_count,' .
                  'sum(r.navigation_total)/sum(r.navigation_count)' .
                  ' AS navigation_latency ' .
                  'FROM oldreport AS r ' .
		  'LEFT OUTER JOIN tag ' .
		  'ON r.final_name = tag.service ' .
                  'WHERE r.timestamp >= ? AND r.timestamp <= ? ' .
		  'AND tag.tag IS NULL ' .
                  'GROUP BY r.final_name ' .
		  'ORDER BY r.final_name;')
      or die "prepare failed";
  return $sth;
}



sub common_aggregate_fields {
  my ($self) = @_;
  return 
    'sum(nreq_tabclosed) AS nreq_tabclosed,' .
    'sum(nreq_200) AS nreq_200,' .
    'sum(nreq_200) AS nreq_300,' .
    'sum(nreq_200) AS nreq_400,' .
    'sum(nreq_200) AS nreq_500,' .
    'sum(nreq_count) AS nreq_count,' .
    'sum(nreq_total)/sum(nreq_count) AS nreq_latency,' .
    'sum(nav_tabclosed) AS nav_tabclosed,' .
    'sum(nav_count) AS nav_count,' .
    'sum(nav_total)/sum(nav_count) AS nav_latency,' .
    'sum(ureq_200) AS ureq_200,' .
    'sum(ureq_200) AS ureq_300,' .
    'sum(ureq_200) AS ureq_400,' .
    'sum(ureq_200) AS ureq_500,' .
    'sum(ureq_count) AS ureq_count,' .
    'sum(ureq_total)/sum(ureq_count) AS ureq_latency';
}

sub service_meta_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT service,' .
		  'min(timestamp) AS min_timestamp,' .
                  'max(timestamp) AS max_timestamp,' .
		  "DATE('now') as date," .
		  $self->common_aggregate_fields() .
		  ' FROM report ' .
                  'WHERE service=? AND ' .
		  "timestamp >= DATETIME('now','-14 days');")
      or die "prepare failed";
  return $sth;
}

sub service_select_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT name,' .
		  $self->common_aggregate_fields() .
		  ' FROM report ' .
		  "WHERE timestamp >= DATETIME('now','-14 days') " .
                  'AND service=? ' .
                  'GROUP BY name ' .
		  'ORDER BY name;')
      or die "prepare failed";
  return $sth;
}


sub service_location_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT location,' .
		  $self->common_aggregate_fields() .
                  ' FROM report ' .
                  'WHERE service=? AND ' .
		  "timestamp >= DATETIME('now','-14 days') " .
                  'GROUP BY location ' .
		  'ORDER BY location;')
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
                  'count(distinct service) AS services,' .
		  $self->common_aggregate_fields() .
                  ' FROM report ' .
                  "WHERE timestamp >= datetime('now','-14 days');" )
      or die "prepare failed";
  return $sth;
}


sub summary_tag_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT tag.tag as tag,' .
                  'count(distinct service) AS services,' .
		  $self->common_aggregate_fields() .
                  ' FROM report ' .
		  'INNER JOIN tag ' .
		  'ON report.service = tag.service ' .
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
                  'count(distinct service) AS services,' .
		  $self->common_aggregate_fields() .
                  ' FROM report ' .
		  'LEFT OUTER JOIN tag ' .
		  'ON report.service = tag.service ' .
                  'WHERE timestamp >= ? AND timestamp <= ? ' .
		  'AND tag.tag is null;')
      or die "prepare failed";
  return $sth;
}

sub summary_location_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT location,' .
                  'count(distinct service) AS services,' .
		  $self->common_aggregate_fields() .
                  ' FROM report ' .
                  'WHERE timestamp >= ? AND timestamp <= ? ' .
                  'GROUP BY location ' .
		  'ORDER BY location;')
      or die "prepare failed";

  return $sth;
}

sub location_meta_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT count(distinct service) AS services,' .
		  'min(timestamp) AS min_timestamp,' .
                  'max(timestamp) AS max_timestamp,' .
		  $self->common_aggregate_fields() .
                  ' FROM report ' .
                  "WHERE timestamp >= datetime('now','-14 days') " .
		  'AND location = ?;')
      or die "prepare failed";
  return $sth;
}


sub location_service_sth {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT service AS service,' .
                  'count(distinct name) AS dependencies,' .
		  $self->common_aggregate_fields() .
                  ' FROM report ' .
                  'WHERE timestamp >= ? AND timestamp <= ? ' .
		  'AND location = ? ' .
                  'GROUP BY service ' .
		  'ORDER BY service;')
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
