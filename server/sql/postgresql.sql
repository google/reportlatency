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


CREATE TABLE report (
  timestamp	TIMESTAMP,
  remote_addr	TEXT,
  user_agent	TEXT,
  name	TEXT,
  final_name	TEXT,
  tz		TEXT,
  version	TEXT,
  options	INTEGER,
  tabupdate_count	INTEGER,
  tabupdate_total	REAL,
  tabupdate_high	REAL,
  tabupdate_low	REAL,
  request_count	INTEGER,
  request_total	REAL,
  request_high	REAL,
  request_low	REAL,
  request_tabclosed	INTEGER,
  navigation_count	INTEGER,
  navigation_total	REAL,
  navigation_high	REAL,
  navigation_low	REAL,
  navigation_tabclosed	INTEGER,
  navigation_error	INTEGER
);

CREATE INDEX idx1 ON report(timestamp);
CREATE INDEX idx2 ON report(name);
CREATE INDEX idx3 ON report(user_agent);
CREATE INDEX idx4 ON report(remote_addr);
CREATE INDEX idx5 ON report(timestamp,name);
CREATE INDEX idx6 ON report(final_name);

CREATE OR REPLACE FUNCTION report_timestamp()
RETURNS TRIGGER AS $timestamp$
   BEGIN
      NEW.timestamp := current_timestamp;
      RETURN NEW;
   END;
$timestamp$ LANGUAGE plpgsql;

CREATE TRIGGER report_timestamp AFTER INSERT ON report
   FOR EACH ROW EXECUTE PROCEDURE report_timestamp();

-- tags to represent platform,owner, groups and other tech used for services
CREATE TABLE tag (
  name TEXT,
  tag  TEXT
);
CREATE INDEX idx14 on tag(name);
CREATE INDEX idx15 on tag(tag);

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
CREATE INDEX idx11 ON location(location);
CREATE INDEX idx16 ON location(timestamp);
CREATE INDEX idx17 ON location(ip);


CREATE TABLE domain (
  owner TEXT,
  match TEXT,
  notmatch TEXT
);
CREATE INDEX idx12 ON domain(owner);
