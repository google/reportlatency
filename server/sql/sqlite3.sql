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
  collected_at	TEXT,
  timestamp	DATETIME,
  remote_addr	TEXT,
  user_agent	TEXT,
  tz		TEXT,
  version	TEXT,
  options	INTEGER
);

CREATE INDEX idx1 ON upload(collected_at);
CREATE INDEX idx2 ON upload(timestamp);
CREATE INDEX idx3 ON upload(remote_addr);
CREATE INDEX idx4 ON upload(user_agent);
CREATE INDEX idx5 ON upload(tz);
CREATE INDEX idx6 ON upload(version);
CREATE INDEX idx7 ON upload(options);

CREATE TABLE service (
  id	INTEGER PRIMARY KEY AUTOINCREMENT,
  name	TEXT
);

CREATE INDEX idx8 ON service(name);


CREATE TABLE request (
  upload	INTEGER,
  name		INTEGER,
  service	INTEGER,
  count		INTEGER,
  total		REAL,
  high		REAL,
  low		REAL,
  tabclosed	INTEGER,
  error		INTEGER,
  FOREIGN KEY(upload) REFERENCES upload(id),
  FOREIGN KEY(name) REFERENCES service(id),
  FOREIGN KEY(service) REFERENCES service(id)
);

CREATE TABLE navigation (
  upload	INTEGER,
  name		INTEGER,
  service	INTEGER,
  count		INTEGER,
  total		REAL,
  high		REAL,
  low		REAL,
  tabclosed	INTEGER,
  error		INTEGER,
  FOREIGN KEY(upload) REFERENCES upload(id),
  FOREIGN KEY(name) REFERENCES service(id),
  FOREIGN KEY(service) REFERENCES service(id)
);

CREATE TABLE tabupdate (
  upload	INTEGER,
  name		INTEGER,
  service	INTEGER,
  count	INTEGER,
  total	REAL,
  high	REAL,
  low	REAL,
  FOREIGN KEY(upload) REFERENCES upload(id),
  FOREIGN KEY(name) REFERENCES service(id),
  FOREIGN KEY(service) REFERENCES service(id)
);

CREATE TRIGGER upload_timestamp AFTER  INSERT ON upload
BEGIN
  UPDATE upload SET timestamp = DATETIME('NOW')  WHERE rowid = new.rowid;
END;

-- tags to represent platform,owner, groups and other tech used for services
CREATE TABLE tag (
  name	INTEGER,
  tag  TEXT,
  FOREIGN KEY(name) REFERENCES service(id)
);
CREATE INDEX idx9 on tag(tag);

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
CREATE INDEX idx10 ON location(location);
CREATE INDEX idx11 ON location(timestamp);
CREATE INDEX idx12 ON location(ip);


CREATE TABLE domain (
  owner TEXT,
  match TEXT,
  notmatch TEXT
);
CREATE INDEX idx13 ON domain(owner);

-- All other databases need to map last_insert_rowid() to their local
-- function.  sqlite3 doesn't have a procedural language and can't map.
