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
  remote_addr	TEXT,
  user_agent	TEXT,
  tz		TEXT,
  version	TEXT,
  options	INTEGER
);

CREATE INDEX upload_collected_on ON upload(collected_on);
CREATE INDEX upload_timestamp ON upload(timestamp);
CREATE INDEX upload_remote_addr ON upload(remote_addr);
CREATE INDEX upload_user_agent ON upload(user_agent);
CREATE INDEX upload_tz ON upload(tz);
CREATE INDEX upload_version ON upload(version);
CREATE INDEX upload_options ON upload(options);


CREATE TABLE request (
  upload	INTEGER,
  name		TEXT,
  service	TEXT,
  count		INTEGER,
  total		REAL,
  high		REAL,
  low		REAL,
  tabclosed	INTEGER,
  error		INTEGER,
  FOREIGN KEY(upload) REFERENCES upload(id)
);
CREATE INDEX request_name ON request(name);
CREATE INDEX request_service ON request(service);

CREATE TABLE navigation (
  upload	INTEGER,
  name		TEXT,
  service	TEXT,
  count		INTEGER,
  total		REAL,
  high		REAL,
  low		REAL,
  tabclosed	INTEGER,
  error		INTEGER,
  FOREIGN KEY(upload) REFERENCES upload(id)
);
CREATE INDEX navigation_name ON navigation(name);
CREATE INDEX navigation_service ON navigation(service);

CREATE TABLE tabupdate (
  upload	INTEGER,
  name		TEXT,
  service	TEXT,
  count	INTEGER,
  total	REAL,
  high	REAL,
  low	REAL,
  FOREIGN KEY(upload) REFERENCES upload(id)
);
CREATE INDEX tabudpate_name ON tabupdate(name);
CREATE INDEX tabudpate_service ON tabupdate(service);

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


CREATE TABLE domain (
  owner TEXT,
  match TEXT,
  notmatch TEXT
);
CREATE INDEX domain_owner ON domain(owner);

-- All other databases need to map last_insert_rowid() to their local
-- function.  sqlite3 doesn't have a procedural language and can't map.
