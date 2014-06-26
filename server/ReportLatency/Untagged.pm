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

package ReportLatency::Untagged;
use ReportLatency::Base;
@ISA = ("ReportLatency::Base");

use strict;
use vars qw($VERSION);

$VERSION     = 0.1;

sub title { return "untagged"; }
sub name_title {  return "Service"; }
sub count_title { return "Depend"; }
sub meta_count_title { return "Services"; }


sub latency_select {
  my ($self,$latency) = @_;
  my $store = $self->{store};
  my $ts = $store->unix_timestamp('u.timestamp');
  my $positive = $store->is_positive('n.count');
  return <<EOS;
SELECT 
  $ts AS timestamp,
  n.count AS count,
  n.high AS high,
  n.low AS low,
  n.total AS total 
FROM current u
INNER JOIN $latency n
ON n.upload=u.id
LEFT OUTER JOIN tag t
ON t.service=n.service
WHERE $positive AND t.tag IS NULL;
EOS
}


sub meta_select {
  my ($self) = @_;
  my $store = $self->{store};
  my $fields = $store->common_aggregate_fields();
  my $st = <<EOS;
SELECT 'total' AS tag,
min(min_timestamp) AS min_timestamp,
max(max_timestamp) AS max_timestamp,
count(distinct r.service) AS services,
$fields
FROM service_report AS r
LEFT OUTER JOIN tag t
ON t.service = r.service
WHERE t.tag IS NULL;
EOS
  return $st;
}

sub tag_select {
  my ($self) = @_;

  my $store = $self->{store};
  my $fields = $store->common_aggregate_fields();
  return <<EOS;
SELECT r.service as tag,
count(distinct r.name) AS services,
$fields
FROM service_report r
LEFT OUTER JOIN tag t
ON r.service = t.service
WHERE t.tag IS NULL
GROUP BY r.service
ORDER BY r.service
;
EOS
}


sub location_select {
  my ($self) = @_;

  my $store = $self->{store};
  my $fields = $store->common_aggregate_fields();
  return <<EOS;
SELECT location,
count(distinct r.service) AS services,
$fields
FROM service_report r
LEFT OUTER JOIN tag t
ON r.service = t.service
WHERE t.tag IS NULL
GROUP BY location
ORDER BY location;
EOS
}

1;
