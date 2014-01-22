--
-- Copyright 2013 Google Inc. All Rights Reserved.
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
  collected_at	TEXT,
  timestamp	TIMESTAMP,
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

CREATE OR REPLACE FUNCTION upload_timestamp()
RETURNS TRIGGER AS $timestamp$
   BEGIN
      NEW.timestamp := current_timestamp;
      RETURN NEW;
   END;
$timestamp$ LANGUAGE plpgsql;

CREATE TRIGGER upload_timestamp AFTER INSERT ON upload
   FOR EACH ROW EXECUTE PROCEDURE upload_timestamp();


CREATE TABLE service (
  id	SERIAL UNIQUE,
  name	TEXT
);

CREATE INDEX idx8 ON service(name);


CREATE TABLE request (
  upload	INTEGER REFERENCES upload(id),
  name		INTEGER REFERENCES service(id),
  service	INTEGER REFERENCES service(id),
  count		INTEGER,
  total		REAL,
  high		REAL,
  low		REAL,
  tabclosed	INTEGER,
  error		INTEGER
);

CREATE TABLE navigation (
  upload	INTEGER REFERENCES upload(id),
  name		INTEGER REFERENCES service(id),
  service	INTEGER REFERENCES service(id),
  count		INTEGER,
  total		REAL,
  high		REAL,
  low		REAL,
  tabclosed	INTEGER,
  error		INTEGER
);

CREATE TABLE tabupdate (
  upload	INTEGER REFERENCES upload(id),
  name		INTEGER REFERENCES service(id),
  service	INTEGER REFERENCES service(id),
  count	INTEGER,
  total	REAL,
  high	REAL,
  low	REAL
);

-- tags to represent platform,owner, groups and other tech used for services
CREATE TABLE tag (
  service	INTEGER REFERENCES service(id),
  tag		TEXT
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
