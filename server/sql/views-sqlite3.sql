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

CREATE VIEW services AS
  SELECT DISTINCT service AS service FROM navigation
  UNION
  SELECT DISTINCT service AS service FROM navigation_request
  UNION
  SELECT DISTINCT service AS service FROM update_request;

CREATE VIEW names AS
  SELECT DISTINCT name AS name FROM navigation
  UNION
  SELECT DISTINCT name AS name FROM navigation_request
  UNION
  SELECT DISTINCT name AS name FROM update_request;

CREATE VIEW report2 AS
    SELECT coalesce(nav.upload,nr.upload) AS upload,
        coalesce(nav.service,nr.service) AS service,
        coalesce(nav.name,nr.name) AS name,
	nav.count AS nav_count, nav.total AS nav_total,
	nav.high AS nav_high, nav.low AS nav_low,
	nav.tabclosed AS nav_tabclosed,
	nr.count AS nreq_count,
	nr.total AS nreq_total,
	nr.high AS nreq_high,
	nr.low AS nreq_low,
	nr.tabclosed AS nreq_tabclosed,
	nr.response200 AS nreq_200,
	nr.response300 AS nreq_300,
	nr.response400 AS nreq_400,
	nr.response500 AS nreq_500
    FROM navigation nav
    LEFT JOIN navigation_request AS nr
    ON nav.upload=nr.upload AND nav.service=nr.service AND nav.name=nr.name
    UNION
    SELECT coalesce(nav.upload,nr.upload) AS upload,
        coalesce(nav.service,nr.service) AS service,
        coalesce(nav.name,nr.name) AS name,
	nav.count AS nav_count, nav.total AS nav_total,
	nav.high AS nav_high, nav.low AS nav_low,
	nav.tabclosed AS nav_tabclosed,
	nr.count AS nreq_count,
	nr.total AS nreq_total,
	nr.high AS nreq_high,
	nr.low AS nreq_low,
	nr.tabclosed AS nreq_tabclosed,
	nr.response200 AS nreq_200,
	nr.response300 AS nreq_300,
	nr.response400 AS nreq_400,
	nr.response500 AS nreq_500
    FROM navigation_request AS nr
    LEFT JOIN navigation nav
    ON nav.upload=nr.upload AND nav.service=nr.service AND nav.name=nr.name;

CREATE VIEW report3 AS
    SELECT coalesce(r2.upload,ur.upload) AS upload,
        coalesce(r2.service,ur.service) AS service,
        coalesce(r2.name,ur.name) AS name,
	r2.nav_count AS nav_count,
	r2.nav_total AS nav_total,
	r2.nav_high AS nav_high,
	r2.nav_low AS nav_low,
	r2.nav_tabclosed AS nav_tabclosed,
	r2.nreq_count AS nreq_count,
	r2.nreq_total AS nreq_total,
	r2.nreq_high AS nreq_high,
	r2.nreq_low AS nreq_low,
	r2.nreq_tabclosed AS nreq_tabclosed,
	r2.nreq_200 AS nreq_200,
	r2.nreq_300 AS nreq_300,
	r2.nreq_400 AS nreq_400,
	r2.nreq_500 AS nreq_500,
	ur.count AS ureq_count,
	ur.total AS ureq_total,
	ur.high AS ureq_high,
	ur.low AS ureq_low,
	ur.response200 AS ureq_200,
	ur.response300 AS ureq_300,
	ur.response400 AS ureq_400,
	ur.response500 AS ureq_500
    FROM report2 r2
    LEFT JOIN update_request AS ur
    ON r2.upload=ur.upload AND r2.service=ur.service AND r2.name=ur.name
    UNION
    SELECT coalesce(r2.upload,ur.upload) AS upload,
        coalesce(r2.service,ur.service) AS service,
        coalesce(r2.name,ur.name) AS name,
	r2.nav_count AS nav_count,
	r2.nav_total AS nav_total,
	r2.nav_high AS nav_high,
	r2.nav_low AS nav_low,
	r2.nav_tabclosed AS nav_tabclosed,
	r2.nreq_count AS nreq_count,
	r2.nreq_total AS nreq_total,
	r2.nreq_high AS nreq_high,
	r2.nreq_low AS nreq_low,
	r2.nreq_tabclosed AS nreq_tabclosed,
	r2.nreq_200 AS nreq_200,
	r2.nreq_300 AS nreq_300,
	r2.nreq_400 AS nreq_400,
	r2.nreq_500 AS nreq_500,
	ur.count AS ureq_count,
        ur.total AS ureq_total,
	ur.high AS ureq_high,
	ur.low AS ureq_low,
	ur.response200 AS ureq_200,
	ur.response300 AS ureq_300,
	ur.response400 AS ureq_400,
	ur.response500 AS ureq_500
    FROM update_request ur
    LEFT JOIN report2 AS r2
    ON r2.upload=ur.upload AND r2.service=ur.service AND r2.name=ur.name;
