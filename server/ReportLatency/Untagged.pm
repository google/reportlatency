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


sub latency_histogram {
  my ($self,$latency) = @_;
  return <<EOS;
SELECT utimestamp AS timestamp,'closed' AS measure,tabclosed AS amount 
FROM current AS u
INNER JOIN $latency AS n ON n.upload=u.id
LEFT OUTER JOIN tag AS t ON t.service=n.service
WHERE t.tag IS NULL AND tabclosed>0
UNION
SELECT utimestamp AS timestamp,'100ms' AS measure,m100 AS amount 
FROM current AS u
INNER JOIN $latency AS n ON n.upload=u.id
LEFT OUTER JOIN tag AS t ON t.service=n.service
WHERE t.tag IS NULL AND m100>0
UNION
SELECT utimestamp AS timestamp,'500ms' AS measure,m500 AS amount 
FROM current AS u
INNER JOIN $latency AS n ON n.upload=u.id
LEFT OUTER JOIN tag AS t ON t.service=n.service
WHERE t.tag IS NULL AND m500>0
UNION
SELECT utimestamp AS timestamp,'1s' AS measure,m1000 AS amount 
FROM current AS u
INNER JOIN $latency AS n ON n.upload=u.id
LEFT OUTER JOIN tag AS t ON t.service=n.service
WHERE t.tag IS NULL AND m1000>0
UNION
SELECT utimestamp AS timestamp,'2s' AS measure,m2000 AS amount 
FROM current AS u
INNER JOIN $latency AS n ON n.upload=u.id
LEFT OUTER JOIN tag AS t ON t.service=n.service
WHERE t.tag IS NULL AND m2000>0
UNION
SELECT utimestamp AS timestamp,'4s' AS measure,m4000 AS amount 
FROM current AS u
INNER JOIN $latency AS n ON n.upload=u.id
LEFT OUTER JOIN tag AS t ON t.service=n.service
WHERE t.tag IS NULL AND m4000>0
UNION
SELECT utimestamp AS timestamp, '10s' AS measure,m10000 AS amount 
FROM current AS u
INNER JOIN $latency AS n ON n.upload=u.id
LEFT OUTER JOIN tag AS t ON t.service=n.service
WHERE t.tag IS NULL AND m10000>0
UNION
SELECT utimestamp AS timestamp,'long' AS measure,
COALESCE(count,0)-COALESCE(m100,0)-COALESCE(m500,0)-COALESCE(m1000,0)-COALESCE(m2000,0)-COALESCE(m4000,0)-COALESCE(m10000,0)-COALESCE(tabclosed,0) AS amount 
FROM current AS u
INNER JOIN $latency AS n ON n.upload=u.id
LEFT OUTER JOIN tag AS t ON t.service=n.service
WHERE t.tag IS NULL AND amount>0
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

sub response_histogram {
  my ($self,$reqtype) = @_;
  return <<EOS;
SELECT utimestamp AS timestamp,
'closed' AS measure,tabclosed AS amount 
FROM current AS u
INNER JOIN $reqtype AS r
ON r.upload=u.id
LEFT OUTER JOIN tag t
ON t.service=r.service
WHERE tabclosed>0 AND t.tag IS NULL
UNION
SELECT utimestamp AS timestamp, '500' AS measure,response500 AS amount 
FROM current AS u
INNER JOIN $reqtype AS r ON r.upload=u.id
LEFT OUTER JOIN tag t ON t.service=r.service
WHERE response500>0 AND t.tag IS NULL
UNION
SELECT utimestamp AS timestamp, '400' AS measure,response400 AS amount 
FROM current AS u
INNER JOIN $reqtype AS r ON r.upload=u.id
LEFT OUTER JOIN tag t ON t.service=r.service
WHERE response400>0 AND t.tag IS NULL;
EOS
}

sub nav_response {
  return <<EOS;
SELECT utimestamp AS timestamp,
'closed' AS measure,tabclosed AS amount 
FROM current AS u
INNER JOIN navigation AS r
ON r.upload=u.id
LEFT OUTER JOIN tag t
ON t.service=r.service
WHERE tabclosed>0 AND t.tag IS NULL
UNION
SELECT utimestamp AS timestamp, '500' AS measure,response500 AS amount 
FROM current AS u
INNER JOIN navigation AS r
ON r.upload=u.id
LEFT OUTER JOIN tag t
ON t.service=r.service
WHERE response500>0 AND t.tag IS NULL
UNION
SELECT utimestamp AS timestamp, '400' AS measure,response400 AS amount 
FROM current AS u
INNER JOIN navigation AS r
ON r.upload=u.id
LEFT OUTER JOIN tag t
ON t.service=r.service
WHERE response400>0 AND t.tag IS NULL
UNION
SELECT utimestamp AS timestamp, '300' AS measure,response300 AS amount 
FROM current AS u
INNER JOIN navigation AS r
ON r.upload=u.id
LEFT OUTER JOIN tag t
ON t.service=r.service
WHERE response300>0 AND t.tag IS NULL;
EOS
}

1;
