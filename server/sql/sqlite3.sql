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
  error400	INTEGER,
  error500	INTEGER,
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
  error400	INTEGER,
  error500	INTEGER,
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
  error400	INTEGER,
  error500	INTEGER,
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
  re TEXT,
  notmatch TEXT
);

CREATE TABLE notmatch (
  tag TEXT,
  re TEXT
);


CREATE VIEW report AS
  SELECT u.timestamp AS timestamp, u.location AS remote_addr,
    u.user_agent AS user_agent, u.tz AS tz, u.version AS version,
    u.options AS options,
    r.name AS name, r.service AS final_name,
    r.count AS request_count, r.total AS request_total,
    r.high AS request_high, r.low AS request_low,
    NULL AS navigation_count, NULL AS navigation_total,
    NULL AS navigation_high, NULL AS navigation_low
    FROM upload AS u 
    JOIN update_request AS r ON u.id=r.upload
  UNION ALL
  SELECT u.timestamp AS timestamp, u.location AS remote_addr,
    u.user_agent AS user_agent, u.tz AS tz, u.version AS version,
    u.options AS options,
    n.name AS name, n.service AS final_name,
    NULL AS request_count, NULL AS request_total,
    NULL AS request_high, NULL AS request_low,
    n.count AS navigation_count, n.total AS navigation_total,
    n.high AS navigation_high, n.low AS navigation_low
    FROM upload AS u 
    JOIN navigation AS n ON u.id=n.upload;

-- All other databases need to map last_insert_rowid() to their local
-- function.  sqlite3 doesn't have a procedural language and can't map.
