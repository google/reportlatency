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

package ReportLatency::Base;

use strict;
use vars qw($VERSION);

$VERSION     = 0.1;

sub new {
  my $class = shift;
  my $self  = bless {}, $class;
  $self->{store} = shift;
  my $begin = $self->{begin} = shift;
  my $end = $self->{end} = shift;
  $self->{store}->create_current_temp_table($begin,$end);

  return $self;
}

sub DESTROY {
  my $self = shift;
}

sub duration {
  my $self = shift;
  my $store = $self->{store};
  return $store->db_to_unix($self->{end}) - $store->db_to_unix($self->{begin});
}

sub latency_select {
  return 'SELECT NULL AS timestamp, NULL AS count, NULL AS high, ' .
    'NULL AS low, NULL AS total WHERE NULL!=NULL;';
}

sub nav_latency_select {
  my ($self) = @_;
  return $self->latency_select('navigation');
}

sub nav_latencies {
  my $self = shift;
  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare($self->nav_latency_select) or die $!;
  $sth->execute() or die $sth->errstr;
  return $sth;
}

sub nreq_latency_select {
  my ($self) = @_;
  return $self->latency_select('navigation_request');
}

sub nreq_latencies {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare($self->nreq_latency_select) or die $!;
  $sth->execute() or die $sth->errstr;
  return $sth;
}

sub ureq_latency_select {
  my ($self) = @_;
  return $self->latency_select('update_request');
}

sub ureq_latencies {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare($self->ureq_latency_select) or die $!;
  $sth->execute() or die $sth->errstr;
  return $sth;
}


sub meta_select {
  my ($self) = @_;
  my $store = $self->{store};
  my $fields = $store->common_aggregate_fields();
  return <<EOS;
SELECT 'total' AS tag,
min(min_timestamp) AS min_timestamp,
max(max_timestamp) AS max_timestamp,
count(distinct service) AS services,
$fields
FROM service_report
EOS
}

sub meta {
  my ($self) = @_;

  if (!defined $self->{meta}) {
    my $store = $self->{store};
    $store->create_service_report_temp_table();
    my $dbh = $store->{dbh};

    my $rowref = $dbh->selectrow_hashref($self->meta_select) or die $!;
    $self->{meta} = $rowref;
  }

  return $self->{meta};
}


sub tag_select {
  my ($self) = @_;

  my $store = $self->{store};
  my $fields = $store->common_aggregate_fields();
  return <<EOS;
SELECT t.tag as tag,
count(distinct r.service) AS services,
$fields
FROM service_report r, tag t
WHERE r.service = t.service
GROUP BY t.tag
UNION
SELECT 'untagged' AS tag,
count(distinct r.service) AS services,
$fields
FROM service_report r
LEFT OUTER JOIN tag t ON r.service = t.service
WHERE t.tag is null
ORDER BY tag
;
EOS
}

sub tag {
  my ($self) = @_;

  my $store = $self->{store};

  $store->create_service_report_temp_table();

  my $dbh = $store->{dbh};
  my $fields = $store->common_aggregate_fields();
  my $sth = $dbh->prepare($self->tag_select ) or die $!;
  $sth->execute() or die $sth->errstr;
  return $sth;
}


sub location_select {
  my ($self) = @_;

  my $store = $self->{store};
  my $fields = $store->common_aggregate_fields();
  return <<EOS;
SELECT location,
count(distinct service) AS services,
$fields
FROM service_report r
GROUP BY location
ORDER BY location;
EOS
}

sub location {
  my ($self) = @_;

  my $store = $self->{store};
  my $dbh = $store->{dbh};
  my $sth = $dbh->prepare( $self->location_select ) or die $!;
  $sth->execute();
  return $sth;
}

sub latency_histogram {
  my ($self,$latency) = @_;
  return <<EOS;
SELECT utimestamp AS timestamp,'closed' AS measure,tabclosed AS amount 
FROM current AS u, $latency AS n
WHERE n.upload=u.id AND tabclosed>0
UNION
SELECT utimestamp AS timestamp,'100ms' AS measure,m100 AS amount 
FROM current AS u, $latency AS n
WHERE n.upload=u.id AND m100>0
UNION
SELECT utimestamp AS timestamp,'500ms' AS measure,m500 AS amount 
FROM current AS u, $latency AS n
WHERE n.upload=u.id AND m500>0
UNION
SELECT utimestamp AS timestamp,'1s' AS measure,m1000 AS amount 
FROM current AS u, $latency AS n
WHERE n.upload=u.id AND m1000>0
UNION
SELECT utimestamp AS timestamp,'2s' AS measure,m2000 AS amount 
FROM current AS u, $latency AS n
WHERE n.upload=u.id AND m2000>0
UNION
SELECT utimestamp AS timestamp,'4s' AS measure,m4000 AS amount 
FROM current AS u, navigation AS n
WHERE n.upload=u.id AND m4000>0
UNION
SELECT utimestamp AS timestamp, '10s' AS measure,m10000 AS amount 
FROM current AS u, $latency AS n
WHERE n.upload=u.id AND m10000>0
UNION
SELECT utimestamp AS timestamp,'long' AS measure,
COALESCE(count,0)-COALESCE(m100,0)-COALESCE(m500,0)-COALESCE(m1000,0)-COALESCE(m2000,0)-COALESCE(m4000,0)-COALESCE(m10000,0)-COALESCE(tabclosed,0) AS amount 
FROM current AS u, $latency AS n
WHERE n.upload=u.id AND amount>0;
EOS
}

sub nav_latency_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare( $self->latency_histogram('navigation'))
   or die $!;
  my $rc = $sth->execute() or die $sth->errstr;

  return $sth;
}

sub nav_response {
  return <<EOS;
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
}

sub nav_response_histogram {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $sth =
    $dbh->prepare( $self->nav_response ) or die $!;
  $sth->execute();
  return $sth;
}


sub nreq_latency_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare( $self->latency_histogram('navigation_request') )
    or die $!;
  $sth->execute() or die $sth->errstr;
  return $sth;
}

sub response_histogram {
  my ($self,$reqtype) = @_;
  return <<EOS;
SELECT utimestamp AS timestamp,
'closed' AS measure,tabclosed AS amount 
FROM current AS u, $reqtype AS r
WHERE r.upload=u.id AND tabclosed>0
UNION
SELECT utimestamp AS timestamp, '500' AS measure,response500 AS amount 
FROM current AS u, $reqtype AS r
WHERE r.upload=u.id AND response500>0
UNION
SELECT utimestamp AS timestamp, '400' AS measure,response400 AS amount 
FROM current AS u, $reqtype AS r
WHERE r.upload=u.id AND response400>0;
EOS
}

sub nreq_response_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth =
    $dbh->prepare($self->response_histogram("navigation_request") )
      or die $!;

  $sth->execute() or die $sth->errstr;
  return $sth;
}

sub ureq_latency_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare( $self->latency_histogram('update_request') )
    or die $!;
  $sth->execute() or die $sth->errstr;
  return $sth;
}

sub ureq_response_histogram {
  my ($self) = @_;

  my $dbh = $self->{store}->{dbh};
  my $sth =
    $dbh->prepare($self->response_histogram("update_request"))
      or die $!;
  $sth->execute() or die $sth->errstr;
  return $sth;
}

1;
