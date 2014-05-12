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
  id		SERIAL UNIQUE,
  collected_on	TEXT,
  timestamp	TIMESTAMP,
  location	TEXT,
  user_agent	TEXT,
  tz		TEXT,
  version	TEXT,
  options	INTEGER
);

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

CREATE TABLE navigation (
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

CREATE TRIGGER upload_timestamp AFTER INSERT ON upload
  FOR EACH ROW EXECUTE PROCEDURE upload_timestamp();

-- tags to represent platform,owner, groups and other tech used for services
CREATE TABLE tag (
  service	TEXT,
  tag  TEXT
);

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

CREATE TABLE match (
  tag TEXT,
  re TEXT
);

CREATE TABLE notmatch (
  tag TEXT,
  re TEXT
);

-- All other databases need to map last_insert_rowid() to their local
-- function.  sqlite3 doesn't have a procedural language and can't map.
