# Copyright 2014 Google Inc. All Rights Reserved.
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

package ReportLatency::Summary;

use strict;
use vars qw($VERSION %options);

$VERSION     = 0.1;
%options = ();


sub new {
  my $class = shift;
  my $self  = bless {}, $class;
  return $self;
}

sub DESTROY {
  my $self = shift;
}


sub nav_latencies {
  my ($self) = @_;

  my $sth = $self->{total_nav_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'n.count AS count,' .
      'n.high AS high,' .
      'n.low AS low,' .
      'n.total AS total ' .
      'FROM navigation n ' .
      'INNER JOIN upload u ON u.id=n.upload ' .
       "WHERE u.timestamp BETWEEN ? AND ? " .
       " AND " . $self->is_positive('n.count') . ";";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{total_nav_latencies_sth} = $sth;
  }

  return $sth;
}

sub nreq_latencies {
  my ($self) = @_;

  my $sth = $self->{total_nreq_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'nr.count AS count,' .
      'nr.high AS high,' .
      'nr.low AS low,' .
      'nr.total AS total ' .
      'FROM navigation_request nr ' .
      'INNER JOIN upload u ON u.id=nr.upload ' .
       "WHERE u.timestamp BETWEEN ? AND ?  AND " .
       $self->is_positive('nr.count') . ";";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{total_nreq_latencies_sth} = $sth;
  }

  return $sth;
}

sub ureq_latencies {
  my ($self) = @_;

  my $sth = $self->{total_ureq_latencies_sth};
  if (! defined $sth) {
    my $dbh = $self->{dbh};
    my $statement='SELECT ' .
      $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
      'ur.count AS count,' .
      'ur.high AS high,' .
      'ur.low AS low,' .
      'ur.total AS total ' .
      'FROM update_request ur ' .
      'INNER JOIN upload u ON u.id=ur.upload ' .
       "WHERE u.timestamp BETWEEN ? AND ? AND " .
       $self->is_positive('ur.count') . ";";
    $sth = $dbh->prepare($statement) or die $!;
    $self->{total_ureq_latencies_sth} = $sth;
  }

  return $sth;
}



sub summary_meta {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare("SELECT 'total' AS tag," .
		  'min(timestamp) AS min_timestamp,' .
                  'max(timestamp) AS max_timestamp,' .
                  'count(distinct service) AS services,' .
		  $self->common_aggregate_fields() .
                  ' FROM upload, report3 ' .
                  "WHERE timestamp BETWEEN ? AND ? " .
		  "AND upload=id;" )
      or die "prepare failed";
  return $sth;
}


sub summary_tag {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT t.tag as tag,' .
                  'count(distinct r.service) AS services,' .
		  $self->common_aggregate_fields() .
                  ' FROM report r ' .
		  'INNER JOIN tag t ' .
		  'ON r.service = t.service ' .
                  'WHERE timestamp BETWEEN ? AND ? ' .
                  'GROUP BY t.tag ' .
		  'ORDER BY t.tag;')
      or die "prepare failed";
  return $sth;
}

sub summary_untagged {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT ' .
                  'count(distinct r.service) AS services,' .
		  $self->common_aggregate_fields() .
                  ' FROM upload u ' .
		  'INNER JOIN report3 r ON u.id=r.upload ' .
		  'LEFT OUTER JOIN tag t ' .
		  'ON r.service = t.service ' .
                  'WHERE timestamp BETWEEN ? AND ? ' .
		  'AND t.tag is null;')
      or die "prepare failed";
  return $sth;
}

sub summary_location {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT location,' .
                  'count(distinct service) AS services,' .
		  $self->common_aggregate_fields() .
                  ' FROM report ' .
                  'WHERE timestamp > ? AND timestamp <= ? ' .
                  'GROUP BY location ' .
		  'ORDER BY location;')
      or die "prepare failed";

  return $sth;
}

sub nav_latency_histogram {
  my ($self,$begin,$end) = @_;

  $self->current_uploads($begin,$end);

  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare( <<EOS ) or die "prepare failed";
SELECT utimestamp AS timestamp,'closed' AS measure,tabclosed AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND tabclosed>0
UNION
SELECT utimestamp AS timestamp,'100ms' AS measure,m100 AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND m100>0
UNION
SELECT utimestamp AS timestamp,'500ms' AS measure,m500 AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND m500>0
UNION
SELECT utimestamp AS timestamp,'1s' AS measure,m1000 AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND m1000>0
UNION
SELECT utimestamp AS timestamp,'2s' AS measure,m2000 AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND m500>0
UNION
SELECT utimestamp AS timestamp, '10s' AS measure,m10000 AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND m10000>0
UNION
SELECT utimestamp AS timestamp,'long' AS measure,
count-m100-m500-m1000-m2000-m10000-tabclosed AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND count>m100+m500+m1000+m2000+m10000+tabclosed
;
EOS

  $sth->execute();
  return $sth;
}

sub nav_response_histogram {
  my ($self,$begin,$end) = @_;

  $self->current_uploads($begin,$end);

  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare( <<EOS ) or die "prepare failed";
SELECT utimestamp AS timestamp,
'closed' AS measure,tabclosed AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND tabclosed>0
UNION
SELECT utimestamp AS timestamp, '500' AS measure,response500 AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND response500>0
UNION
SELECT utimestamp AS timestamp, '400' AS measure,response400 AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND response400>0
UNION
SELECT utimestamp AS timestamp, '300' AS measure,response300 AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND response300>0;
EOS

  $sth->execute();
  return $sth;
}


sub nreq_latency_histogram {
  my ($self,$begin,$end) = @_;

  $self->current_uploads($begin,$end);

  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare( <<EOS ) or die "prepare failed";
SELECT utimestamp AS timestamp,'closed' AS measure,tabclosed AS amount 
FROM current AS u, navigation_request AS r
WHERE r.upload=u.id AND tabclosed>0
UNION
SELECT utimestamp AS timestamp,'100ms' AS measure,m100 AS amount 
FROM current AS u, navigation_request AS r
WHERE r.upload=u.id AND m100>0
UNION
SELECT utimestamp AS timestamp,'500ms' AS measure,m500 AS amount 
FROM current AS u, navigation_request AS r
WHERE r.upload=u.id AND m500>0
UNION
SELECT utimestamp AS timestamp,'1s' AS measure,m1000 AS amount 
FROM current AS u, navigation_request AS r
WHERE r.upload=u.id AND m1000>0
UNION
SELECT utimestamp AS timestamp,'2s' AS measure,m2000 AS amount 
FROM current AS u, navigation_request AS r
WHERE r.upload=u.id AND m500>0
UNION
SELECT utimestamp AS timestamp, '10s' AS measure,m10000 AS amount 
FROM current AS u, navigation_request AS r
WHERE r.upload=u.id AND m10000>0
UNION
SELECT utimestamp AS timestamp,'long' AS measure,
count-m100-m500-m1000-m2000-m10000-tabclosed AS amount 
FROM current AS u, navigation_request AS r
WHERE r.upload=u.id AND count>m100+m500+m1000+m2000+m10000+tabclosed
;
EOS

  $sth->execute();
  return $sth;
}

sub nreq_response_histogram {
  my ($self,$begin,$end) = @_;

  $self->current_uploads($begin,$end);

  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare( <<EOS ) or die "prepare failed";
SELECT utimestamp AS timestamp,
'closed' AS measure,tabclosed AS amount 
FROM current AS u, navigation_request AS r
WHERE r.upload=u.id AND tabclosed>0
UNION
SELECT utimestamp AS timestamp, '500' AS measure,response500 AS amount 
FROM current AS u, navigation_request AS r
WHERE r.upload=u.id AND response500>0
UNION
SELECT utimestamp AS timestamp, '400' AS measure,response400 AS amount 
FROM current AS u, navigation_request AS r
WHERE r.upload=u.id AND response400>0;
EOS

  $sth->execute();
  return $sth;
}

sub ureq_latency_histogram {
  my ($self,$begin,$end) = @_;

  $self->current_uploads($begin,$end);

  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare( <<EOS ) or die "prepare failed";
SELECT utimestamp AS timestamp,'closed' AS measure,tabclosed AS amount 
FROM current AS u, update_request AS r
WHERE r.upload=u.id AND tabclosed>0
UNION
SELECT utimestamp AS timestamp,'100ms' AS measure,m100 AS amount 
FROM current AS u, update_request AS r
WHERE r.upload=u.id AND m100>0
UNION
SELECT utimestamp AS timestamp,'500ms' AS measure,m500 AS amount 
FROM current AS u, update_request AS r
WHERE r.upload=u.id AND m500>0
UNION
SELECT utimestamp AS timestamp,'1s' AS measure,m1000 AS amount 
FROM current AS u, update_request AS r
WHERE r.upload=u.id AND m1000>0
UNION
SELECT utimestamp AS timestamp,'2s' AS measure,m2000 AS amount 
FROM current AS u, update_request AS r
WHERE r.upload=u.id AND m500>0
UNION
SELECT utimestamp AS timestamp, '10s' AS measure,m10000 AS amount 
FROM current AS u, update_request AS r
WHERE r.upload=u.id AND m10000>0
UNION
SELECT utimestamp AS timestamp,'long' AS measure,
count-m100-m500-m1000-m2000-m10000-tabclosed AS amount 
FROM current AS u, update_request AS r
WHERE r.upload=u.id AND count>m100+m500+m1000+m2000+m10000+tabclosed
;
EOS

  $sth->execute();
  return $sth;
}

sub ureq_response_histogram {
  my ($self,$begin,$end) = @_;

  $self->current_uploads($begin,$end);

  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare( <<EOS ) or die "prepare failed";
SELECT utimestamp AS timestamp,
'closed' AS measure,tabclosed AS amount 
FROM current AS u, update_request AS r
WHERE r.upload=u.id AND tabclosed>0
UNION
SELECT utimestamp AS timestamp, '500' AS measure,response500 AS amount 
FROM current AS u, update_request AS r
WHERE r.upload=u.id AND response500>0
UNION
SELECT utimestamp AS timestamp, '400' AS measure,response400 AS amount 
FROM current AS u, update_request AS r
WHERE r.upload=u.id AND response400>0;
EOS

  $sth->execute();
  return $sth;
}


sub extension_version {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT version AS name,count(*) AS value' .
                  ' FROM upload AS u ' .
                  'WHERE timestamp BETWEEN ? AND ? ' .
                  'GROUP BY version ' .
		  'ORDER BY version;')
      or die "prepare failed";
  return $sth;
}

sub extension_version_histogram {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT ' .
		  $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
		  'version AS measure,1 AS amount' .
                  ' FROM upload AS u ' .
                  "WHERE u.timestamp BETWEEN ? AND ? ;")
      or die "prepare failed";
  return $sth;
}

sub user_agent {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT user_agent AS name,count(*) AS value' .
                  ' FROM upload ' .
                  'WHERE timestamp BETWEEN ? AND ? ' .
                  'GROUP BY user_agent ' .
		  'ORDER BY user_agent;')
      or die "prepare failed";
  return $sth;
}

sub user_agent_histogram {
  my ($self) = @_;
  my $dbh = $self->{dbh};
  my $sth =
    $dbh->prepare('SELECT ' .
		  $self->unix_timestamp('u.timestamp') . ' AS timestamp,' .
		  'user_agent AS measure,1 AS amount' .
                  ' FROM upload AS u ' .
                  "WHERE u.timestamp BETWEEN ? AND ?;")
      or die "prepare failed";
  return $sth;
}

1;
