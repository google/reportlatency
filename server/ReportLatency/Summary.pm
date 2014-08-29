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
use ReportLatency::Base;
@ISA = ("ReportLatency::Base");

use strict;
use vars qw($VERSION);

$VERSION     = 0.1;

sub title { return "Summary"; }
sub name_title { return "Tag"; }
sub count_title { return "Services"; }
sub meta_count_title { return "Services"; }

sub tag_url {
  my ($self, $view, $name) = @_;
  return $view->tag_url($name);
}

sub latency_select {
  my ($self,$latency) = @_;
  my $store = $self->{store};
  return 'SELECT ' .
    $self->{store}->unix_timestamp('u.timestamp') . ' AS timestamp,' .
    'n.count AS count,' .
    'n.high AS high,' .
    'n.low AS low,' .
    'n.total AS total ' .
    "FROM current u, $latency n " .
    'WHERE n.upload=u.id AND ' .
     $self->{store}->is_positive('n.count') . ';';
}

sub extension_version_select {
  return <<EOS;
SELECT version AS name,count(*) AS value
FROM current
GROUP BY version
ORDER BY version;
EOS
}

sub extension_version_histogram_select {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $ts = $self->{store}->unix_timestamp('timestamp');
  return <<EOS;
SELECT $ts AS timestamp,version AS measure,1 AS amount FROM current;
EOS
}

sub user_agent_select {
  return <<EOS;
SELECT user_agent AS name,count(*) AS value
FROM current
GROUP BY user_agent
ORDER BY user_agent;
EOS
}

sub useragent_histogram_select {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $ts = $self->{store}->unix_timestamp('timestamp');
  return <<EOS;
SELECT $ts AS timestamp,user_agent AS measure,1 AS amount FROM current;
EOS
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


sub extension_version_histogram {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $sth =
    $dbh->prepare($self->extension_version_histogram_select)
      or die $!;
  $sth->execute() or die $sth->errstr;
  return $sth;
}

sub useragent_histogram {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare($self->useragent_histogram_select) or die $!;
  $sth->execute() or die $sth->errstr;
  return $sth;
}

sub user_agent {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $sth =
    $dbh->prepare($self->user_agent_select) or die $!;
  $sth->execute() or die $sth->errstr;
  return $sth;
}

sub extension_version {
  my ($self) = @_;
  my $dbh = $self->{store}->{dbh};
  my $sth = $dbh->prepare($self->extension_version_select) or die $!;
  $sth->execute() or die $sth->errstr;
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
FROM current AS u, $latency AS n
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

1;
