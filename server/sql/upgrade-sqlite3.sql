-- upgrade the previous schema to the current schema
-- 1.5.3->1.5.4 in this version
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

BEGIN;
DROP VIEW report;
DROP VIEW report3;
DROP VIEW report2;
DROP VIEW names;
DROP VIEW services;
DROP INDEX location_ip;
DROP INDEX location_location;
DROP INDEX location_timestamp;
DROP INDEX navigation_name;
DROP INDEX navigation_request_name;
DROP INDEX navigation_request_service;
DROP INDEX navigation_request_upload;
DROP INDEX navigation_service;
DROP INDEX navigation_upload;
DROP INDEX tag_service;
DROP INDEX tag_tag;
DROP INDEX update_request_name;
DROP INDEX update_request_service;
DROP INDEX update_request_upload;
DROP INDEX upload_collected_on;
DROP INDEX upload_id;
DROP INDEX upload_location;
DROP INDEX upload_options;
DROP INDEX upload_timestamp;
DROP INDEX upload_tz;
DROP INDEX upload_user_agent;
DROP INDEX upload_version;
ALTER TABLE navigation ADD COLUMN response200 INTEGER;
ALTER TABLE navigation ADD COLUMN response300 INTEGER;
ALTER TABLE navigation ADD COLUMN response400 INTEGER;
ALTER TABLE navigation ADD COLUMN response500 INTEGER;
.read views-sqlite3.sql
.read indices-sqlite3.sql
END;
