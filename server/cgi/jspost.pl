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

use Mojolicious::Lite;
use DBI;
use ReportLatency::utils;
use ReportLatency::Store;
use strict;

my $dbh = latency_dbh();
my $store = new ReportLatency::Store(dbh => $dbh);

post '/' => sub {
  my $self = shift;
  my $remote_addr =
    $store->aggregate_remote_address($ENV{'REMOTE_ADDR'},
				     $ENV{'HTTP_X_FORWARDED_FOR'});
  my $user_agent = aggregate_user_agent($ENV{'HTTP_USER_AGENT'});

  my $type = $self->header;
  my $content_type = $self->content_type;

  if ($content_type eq 'application/json') {
    my $reply = CGI->new;
    $self->render('good');
  } else {
   $self->render('bad', status => 400 );
  }
};


app->start;

__DATA__

@@ good.txt.ep
Thank you for your report!

@@ badtype.txt.ep
Thank you for your <%= $type %> report, but it is <%= $content_type %> not application/json.
