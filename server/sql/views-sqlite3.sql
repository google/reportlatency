--
-- Copyright 2014 Google Inc. All Rights Reserved.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.


CREATE VIEW report AS
    SELECT u.*,n.service,n.name,
	n.count AS nav_count, n.total AS nav_total,
	n.high AS nav_high, n.low AS nav_low,
	n.tabclosed AS nav_tabclosed,
	NULL AS nreq_count, NULL AS nreq_total,
	NULL AS nreq_high, NULL AS nreq_low,
	NULL AS nreq_tabclosed,
	NULL AS nreq_200, NULL AS nreq_300,
	NULL AS nreq_400, NULL AS nreq_500,
	NULL AS ureq_count, NULL AS ureq_total,
	NULL AS ureq_high, NULL AS ureq_low,
	NULL AS ureq_tabclosed,
	NULL AS ureq_200, NULL AS ureq_300,
	NULL AS ureq_400, NULL AS ureq_500
    FROM upload AS u
    JOIN navigation AS n ON u.id=n.upload
  UNION
    SELECT u.*,nr.service,nr.name,
	NULL AS nav_count,NULL AS nav_total,
	NULL AS nav_high,NULL nav_low,
	NULL AS nav_tabclosed,
	nr.count AS nreq_count,nr.total AS nreq_total,
	nr.high AS nreq_high,nr.low AS nreq_low,
	nr.tabclosed AS nreq_tabclosed,
	nr.response200 AS nreq_200,
	nr.response300 AS nreq_300,
	nr.response400 AS nreq_400,
	nr.response500 AS nreq_500,
	NULL AS ureq_count, NULL AS ureq_total,
	NULL AS ureq_high, NULL AS ureq_low,
	NULL AS ureq_tabclosed,
	NULL AS ureq_200, NULL AS ureq_300,
	NULL AS ureq_400, NULL AS ureq_500
    FROM upload AS u
    JOIN navigation_request AS nr ON u.id=nr.upload
  UNION
    SELECT u.*,ur.service,ur.name,
	NULL AS nav_count,NULL AS nav_total,
	NULL AS nav_high,NULL nav_low,
	NULL AS nav_tabclosed,
	NULL AS nreq_count, NULL AS nreq_total,
	NULL AS nreq_high, NULL AS nreq_low,
	NULL AS nreq_tabclosed,
	NULL AS nreq_200, NULL AS nreq_300,
	NULL AS nreq_400, NULL AS nreq_500,
	ur.count AS ureq_count,ur.total AS ureq_total,
	ur.high AS ureq_high,ur.low AS ureq_low,
	ur.tabclosed AS ureq_tabclosed,
	ur.response200 AS ureq_200,
	ur.response300 AS ureq_300,
	ur.response400 AS ureq_400,
	ur.response500 AS ureq_500
    FROM upload AS u
    JOIN update_request AS ur ON u.id=ur.upload;


-- just some column differences.  Going away.
CREATE VIEW oldreport AS
  SELECT id, timestamp, location AS remote_addr,
    user_agent, tz, version,
    options,
    service AS final_name,
    name,
    ureq_count AS request_count, ureq_total AS request_total,
    ureq_high AS request_high, ureq_low AS request_low,
    nav_count AS navigation_count, nav_total AS navigation_total,
    nav_high AS navigation_high, nav_low AS navigation_low
    FROM report;

CREATE VIEW services AS
  SELECT DISTINCT service FROM navigation;
  UNION ALL
  SELECT DISTINCT service FROM navigation_request;
  UNION ALL
  SELECT DISTINCT service FROM update_request;

CREATE VIEW names AS
  SELECT DISTINCT name FROM navigation;
  UNION ALL
  SELECT DISTINCT name FROM navigation_request;
  UNION ALL
  SELECT DISTINCT name FROM update_request;
