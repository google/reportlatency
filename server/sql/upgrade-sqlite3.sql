-- upgrade the previous schema to the current schema
-- 1.4.5 -> 1.4.6 in this version
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

begin;
DROP INDEX navigation_request_name;
DROP INDEX navigation_request_service;
DROP INDEX update_request_name;
DROP INDEX update_request_service;
DROP INDEX navigation_name;
DROP INDEX navigation_service;
ALTER TABLE navigation RENAME TO old_navigation;
ALTER TABLE navigation_request RENAME TO old_navigation_request;
ALTER TABLE update_request RENAME TO old_update_request;

-- changed parts pulled from current sqlite3 schema.

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


end;

-- migrate the old data into the new tables here
