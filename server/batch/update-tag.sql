--
-- run this transaction periodically to tag new services
--
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

BEGIN;
DELETE FROM tag;

INSERT INTO tag
  SELECT distinct report.name, domain.owner
    FROM report,domain
    LEFT JOIN tag t2 ON t2.name = report.name 
    WHERE t2.name IS NULL AND report.name LIKE domain.match; 

INSERT INTO tag
  SELECT distinct report.final_name, domain.owner
    FROM report,domain
    LEFT JOIN tag t2 ON t2.name = report.final_name 
    WHERE t2.name IS NULL AND report.final_name LIKE domain.match; 

INSERT INTO tag
  SELECT distinct report.name, domain.owner
    FROM report,domain
    LEFT JOIN tag t2 ON t2.name = report.name 
    WHERE t2.name IS NULL AND report.name NOT LIKE domain.notmatch; 

INSERT INTO tag
  SELECT distinct report.final_name, domain.owner
    FROM report,domain
    LEFT JOIN tag t2 ON t2.name = report.final_name 
    WHERE t2.name IS NULL AND report.final_name NOT LIKE domain.notmatch; 

END;
