--
-- Copyright 2013,2014 Google Inc. All Rights Reserved.
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


CREATE TABLE upload (
  id		INTEGER PRIMARY KEY AUTOINCREMENT,
  collected_on	TEXT,
  timestamp	DATETIME,
  location	TEXT,
  user_agent	TEXT,
  tz		TEXT,
  version	TEXT,
  options	INTEGER
);

CREATE INDEX upload_collected_on ON upload(collected_on);
CREATE INDEX upload_timestamp ON upload(timestamp);
CREATE INDEX upload_location ON upload(location);
CREATE INDEX upload_user_agent ON upload(user_agent);
CREATE INDEX upload_tz ON upload(tz);
CREATE INDEX upload_version ON upload(version);
CREATE INDEX upload_options ON upload(options);

-- requests that happen during a navigation event
CREATE TABLE navigation_request (
  upload	INTEGER,
  name		TEXT,
  service	TEXT,
  count		INTEGER,
  total		REAL,
  high		REAL,
  low		REAL,
  tabclosed	INTEGER,
  response200	INTEGER,
  response300	INTEGER,
  response400	INTEGER,
  response500	INTEGER,
  FOREIGN KEY(upload) REFERENCES upload(id)
);
CREATE INDEX navigation_request_name ON navigation_request(name);
CREATE INDEX navigation_request_service ON navigation_request(service);

-- requests that occur after navigation completes
CREATE TABLE update_request (
  upload	INTEGER,
  name		TEXT,
  service	TEXT,
  count		INTEGER,
  total		REAL,
  high		REAL,
  low		REAL,
  tabclosed	INTEGER,
  response200	INTEGER,
  response300	INTEGER,
  response400	INTEGER,
  response500	INTEGER,
  FOREIGN KEY(upload) REFERENCES upload(id)
);
CREATE INDEX update_request_name ON update_request(name);
CREATE INDEX update_request_service ON update_request(service);

CREATE TABLE navigation (
  upload	INTEGER,
  name		TEXT,
  service	TEXT,
  count		INTEGER,
  total		REAL,
  high		REAL,
  low		REAL,
  tabclosed	INTEGER,
  FOREIGN KEY(upload) REFERENCES upload(id)
);
CREATE INDEX navigation_name ON navigation(name);
CREATE INDEX navigation_service ON navigation(service);

CREATE TRIGGER upload_timestamp AFTER  INSERT ON upload
BEGIN
  UPDATE upload SET timestamp = DATETIME('NOW')  WHERE rowid = new.rowid;
END;

-- tags to represent platform,owner, groups and other tech used for services
CREATE TABLE tag (
  service	TEXT,
  tag  TEXT
);
CREATE INDEX tag_tag on tag(tag);
CREATE INDEX tag_service on tag(service);

-- For speed cache reverse DNS lookups on REMOTE_ADDR or HTTP_X_FORWARDED_FOR.
-- Location defaults to the class C or subdomain if available,
-- but may be overridden by local office names, etc.
-- Purge old entries periodically, to pull fresh reverse DNS entries.
CREATE TABLE location (
  timestamp DATE,
  ip	TEXT,
  rdns	TEXT,
  location TEXT
);
CREATE INDEX location_location ON location(location);
CREATE INDEX location_timestamp ON location(timestamp);
CREATE INDEX location_ip ON location(ip);


CREATE TABLE match (
  tag TEXT,
  re TEXT
);

CREATE TABLE notmatch (
  tag TEXT,
  re TEXT
);

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

-- All other databases need to map last_insert_rowid() to their local
-- function.  sqlite3 doesn't have a procedural language and can't map.
