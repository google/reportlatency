#!/usr/bin/perl -wT
#
# Copyright 2013 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use DBI;
use CGI;
use ReportLatency::utils;
use ReportLatency::Store;
use ReportLatency::CGIView;

use strict;


sub main {
  my $dbh = latency_dbh('backup');
  my $store = new ReportLatency::Store(dbh => $dbh);
  my $view = new ReportLatency::CGIView($store);
  my $q = new CGI;
  my $tag_name = $q->param('name');

  print $q->header(-type => 'text/html');
  print $view->tag_html($tag_name);
}

main() unless caller();
