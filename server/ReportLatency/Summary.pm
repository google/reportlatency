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

1;
