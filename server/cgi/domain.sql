-- allow grouping of reports by domain owner (eg. Google)
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


INSERT INTO domain(owner,match) VALUES('Google','google.com');
INSERT INTO domain(owner,match) VALUES('Google','google.com:%');
INSERT INTO domain(owner,match) VALUES('Google','%.google.com');
INSERT INTO domain(owner,match) VALUES('Google','%.google.com/%');

INSERT INTO domain(owner,match) VALUES('Google','googleplex.com');
INSERT INTO domain(owner,match) VALUES('Google','%.googleplex.com');

INSERT INTO domain(owner,match) VALUES('Google','admob.com');
INSERT INTO domain(owner,match) VALUES('Google','android.com');
INSERT INTO domain(owner,match) VALUES('Google','appspot.com');
INSERT INTO domain(owner,match) VALUES('Google','blogblog.com');
INSERT INTO domain(owner,match) VALUES('Google','blogger.com');
INSERT INTO domain(owner,match) VALUES('Google','blogspot.com');
INSERT INTO domain(owner,match) VALUES('Google','doubleclick.net');
INSERT INTO domain(owner,match) VALUES('Google','chrome.com');
INSERT INTO domain(owner,match) VALUES('Google','g.co');
INSERT INTO domain(owner,match) VALUES('Google','ggpht.com');
INSERT INTO domain(owner,match) VALUES('Google','gmail.com');
INSERT INTO domain(owner,match) VALUES('Google','goo.gl');
INSERT INTO domain(owner,match) VALUES('Google','google.net');
INSERT INTO domain(owner,match) VALUES('Google','google.org');
INSERT INTO domain(owner,match) VALUES('Google','googleadservices.com');
INSERT INTO domain(owner,match) VALUES('Google','googleapis.com');
INSERT INTO domain(owner,match) VALUES('Google','googlecode.com');
INSERT INTO domain(owner,match) VALUES('Google','googledrive.com');
INSERT INTO domain(owner,match) VALUES('Google','googlegroups.com');
INSERT INTO domain(owner,match) VALUES('Google','googleitahosted.com');
INSERT INTO domain(owner,match) VALUES('Google','googleratings.com');
INSERT INTO domain(owner,match) VALUES('Google','googlesource.com');
INSERT INTO domain(owner,match) VALUES('Google','googlesyndication.com');
INSERT INTO domain(owner,match) VALUES('Google','googletagmanager.com');
INSERT INTO domain(owner,match) VALUES('Google','googletagservices.com');
INSERT INTO domain(owner,match) VALUES('Google','googleusercontent.com');
INSERT INTO domain(owner,match) VALUES('Google','gstatic.com');
INSERT INTO domain(owner,match) VALUES('Google','itasoftware.com');
INSERT INTO domain(owner,match) VALUES('Google','keyhole.com');
INSERT INTO domain(owner,match) VALUES('Google','urchin.com');
INSERT INTO domain(owner,match) VALUES('Google','widevine.com');
INSERT INTO domain(owner,match) VALUES('Google','widevine.tv');
INSERT INTO domain(owner,match) VALUES('Google','withgoogle.com');
INSERT INTO domain(owner,match) VALUES('Google','youtu.be');
INSERT INTO domain(owner,match) VALUES('Google','youtube.com');
INSERT INTO domain(owner,match) VALUES('Google','youtube-nocookie.com');
INSERT INTO domain(owner,match) VALUES('Google','ytimg.com');
