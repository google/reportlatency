-- upgrade the previous schema to the current schema
-- 1.6.0->1.6.1 in this version
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
ALTER TABLE navigation_request ADD COLUMN m4000 INTEGER;
ALTER TABLE update_request ADD COLUMN m4000 INTEGER;
ALTER TABLE navigation ADD COLUMN m4000 INTEGER;
END;
