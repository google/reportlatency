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


CREATE VIEW reportn AS
    SELECT nav.upload AS upload,
        nav.service AS service,
        nav.name AS name,
	nav.count AS nav_count,
        nav.total AS nav_total,
	nav.high AS nav_high,
        nav.low AS nav_low,
	nav.tabclosed AS nav_tabclosed,
	nav.response200 AS nav_200,
	nav.response300 AS nav_300,
	nav.response400 AS nav_400,
	nav.response500 AS nav_500,
	0 AS nreq_count,
	0 AS nreq_total,
	0 AS nreq_high,
	0 AS nreq_low,
	0 AS nreq_tabclosed,
	0 AS nreq_200,
	0 AS nreq_300,
	0 AS nreq_400,
	0 AS nreq_500,
	0 AS ureq_count,
	0 AS ureq_total,
	0 AS ureq_high,
	0 AS ureq_low,
	0 AS ureq_200,
	0 AS ureq_300,
	0 AS ureq_400,
	0 AS ureq_500
    FROM navigation nav;

CREATE VIEW reportnr AS
    SELECT nr.upload AS upload,
        nr.service AS service,
        nr.name AS name,
	0 AS nav_count,
        0 AS nav_total,
	0 AS nav_high,
        0 AS nav_low,
	0 AS nav_tabclosed,
	0 AS nav_200,
	0 AS nav_300,
	0 AS nav_400,
	0 AS nav_500,
	nr.count AS nreq_count,
	nr.total AS nreq_total,
	nr.high AS nreq_high,
	nr.low AS nreq_low,
	nr.tabclosed AS nreq_tabclosed,
	nr.response200 AS nreq_200,
	nr.response300 AS nreq_300,
	nr.response400 AS nreq_400,
	nr.response500 AS nreq_500,
	0 AS ureq_count,
	0 AS ureq_total,
	0 AS ureq_high,
	0 AS ureq_low,
	0 AS ureq_200,
	0 AS ureq_300,
	0 AS ureq_400,
	0 AS ureq_500
    FROM navigation_request nr;

CREATE VIEW reportur AS
    SELECT ur.upload AS upload,
        ur.service AS service,
        ur.name AS name,
	0 AS nav_count,
        0 AS nav_total,
	0 AS nav_high,
        0 AS nav_low,
	0 AS nav_tabclosed,
	0 AS nav_200,
	0 AS nav_300,
	0 AS nav_400,
	0 AS nav_500,
	0 AS nreq_count,
	0 AS nreq_total,
	0 AS nreq_high,
	0 AS nreq_low,
	0 AS nreq_tabclosed,
	0 AS nreq_200,
	0 AS nreq_300,
	0 AS nreq_400,
	0 AS nreq_500,
	ur.count AS ureq_count,
	ur.total AS ureq_total,
	ur.high AS ureq_high,
	ur.low AS ureq_low,
	ur.response200 AS ureq_200,
	ur.response300 AS ureq_300,
	ur.response400 AS ureq_400,
	ur.response500 AS ureq_500
    FROM update_request ur;

CREATE VIEW report3 AS
    SELECT * FROM reportn
    UNION
    SELECT * from reportnr
    UNION
    SELECT * from reportur;


CREATE VIEW report AS
    SELECT u.*,r.*
    FROM upload u, report3 r
    WHERE u.id=r.upload;
