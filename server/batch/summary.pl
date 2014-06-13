#!/usr/bin/perl -w
#
# Copyright 2013,2014 Google Inc. All Rights Reserved.
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


use ReportLatency::utils;
use ReportLatency::AtomicFile;
use ReportLatency::Spectrum;
use ReportLatency::StackedGraph;
use ReportLatency::StaticView;
use ReportLatency::Store;
use ReportLatency::Summary;
use DBI;
use GD;
use Getopt::Long;
use Pod::Usage;
use strict;

my $days=14;
my $hours=0.5;
my $width=$days*24/$hours * 3 / 4;
my $height=int($width/2);

my $navwidth = $width;
my $navheight = $height;

my $reqwidth = $width;
my $reqheight = $height;

my $histwidth = $width/4;
my $histheight = $height;

my $interval = $hours * 3600;
my $border=24;

my $nav_ceiling = 30000; # 30s max for navigation images
my $nreq_ceiling = 30000; # 30s max for navigation request images
my $ureq_ceiling = 500000; # 300s max for update request images
my $req_floor = 10; # 30ms min for request images

sub user_agents {
  my ($store,$options) = @_;
  my $sth = $store->user_agent_sth();

  my $t = time;
  my $begin = $store->db_timestamp($t - $ReportLatency::utils::duration);
  my $end = $store->db_timestamp($t);
  my $rc = $sth->execute($begin, $end);

  my $graph = new ReportLatency::StackedGraph( width => $histwidth,
					      height => $histheight,
					      duration => $ReportLatency::utils::duration,
					      border => 24 );
  
  while (my $row = $sth->fetchrow_hashref) {
    $graph->add_row($row);
  }

  my $png = new ReportLatency::AtomicFile("tags/summary/useragents.png");
  print $png $graph->img()->png();
  close($png);

  benchmark_point("useragents.png");
}

sub extensions {
  my ($store,$options) = @_;
  my $sth = $store->extension_version_sth();

  my $t = time;
  my $begin = $store->db_timestamp($t - $ReportLatency::utils::duration);
  my $end = $store->db_timestamp($t);
  my $rc = $sth->execute($begin, $end);

  my $graph = new ReportLatency::StackedGraph( width => $histwidth,
					      height => $histheight,
					      duration => $ReportLatency::utils::duration,
					      border => 24 );
  
  while (my $row = $sth->fetchrow_hashref) {
    $graph->add_row($row);
  }

  my $png = new ReportLatency::AtomicFile("tags/summary/extensions.png");
  print $png $graph->img()->png();
  close($png);
  benchmark_point("extensions.png");
}

sub total_graph {
  my ($qobj) = @_;

  benchmark_point("start total_graph()");
  my $begin = $qobj->{begin};
  my $end = $qobj->{end};

  my $sth = $qobj->nav_latencies();
  my $spectrum = new ReportLatency::Spectrum( width => $navwidth,
					      height => $navheight,
					      duration => $ReportLatency::utils::duration,
					      ceiling => $nav_ceiling,
					      border => 24 );  
  while (my $row = $sth->fetchrow_hashref) {
    $spectrum->add_row($row);
  }
  my $png = new ReportLatency::AtomicFile("tags/summary/nav_spectrum.png");
  print $png $spectrum->png();
  close($png);

  benchmark_point("nav_spectrum.png");

  $sth = $qobj->nreq_latencies();
  $spectrum = new ReportLatency::Spectrum( width => $reqwidth,
					   height => $reqheight,
					   duration => $ReportLatency::utils::duration,
					   ceiling => $nreq_ceiling,
					   floor   => $req_floor,
					   border => 24 );
  while (my $row = $sth->fetchrow_hashref) {
    $spectrum->add_row($row);
  }
  $png = new ReportLatency::AtomicFile("tags/summary/nreq_spectrum.png");
  print $png $spectrum->png();
  close($png);

  benchmark_point("nreq_spectrum.png");

  $sth = $qobj->ureq_latencies();
  $spectrum = new ReportLatency::Spectrum( width => $reqwidth,
					   height => $reqheight,
					   duration => $ReportLatency::utils::duration,
					   ceiling => $ureq_ceiling,
					   floor   => $req_floor,
					   border => 24 );
  while (my $row = $sth->fetchrow_hashref) {
    $spectrum->add_row($row);
  }
  $png = new ReportLatency::AtomicFile("tags/summary/ureq_spectrum.png");
  print $png $spectrum->png();
  close($png);

  benchmark_point("ureq_spectrum.png");

  $sth = $qobj->nav_latency_histogram();
  my $graph = new ReportLatency::StackedGraph( width => $histwidth,
					      height => $histheight,
					      duration => $ReportLatency::utils::duration,
					      border => 24 );
  while (my $row = $sth->fetchrow_hashref) {
    $graph->add_row($row);
  }
  $graph->reorder('closed','long','10s','2s','1s','500ms','100ms');
  $png = new ReportLatency::AtomicFile("tags/summary/nav_latency.png");
  print $png $graph->img()->png();
  close($png);

  benchmark_point("nav_latency.png");

  $sth = $qobj->nav_response_histogram();
  $graph = new ReportLatency::StackedGraph( width => $histwidth,
					      height => $histheight,
					      duration => $ReportLatency::utils::duration,
					      border => 24 );
  while (my $row = $sth->fetchrow_hashref) {
    $graph->add_row($row);
  }
  $graph->reorder('closed','500','400','300');
  $png = new ReportLatency::AtomicFile("tags/summary/nav_error.png");
  print $png $graph->img()->png();
  close($png);

  benchmark_point("nav_error.png");

  $sth = $qobj->nreq_latency_histogram();
  $graph = new ReportLatency::StackedGraph( width => $histwidth,
					    height => $histheight,
					    duration => $ReportLatency::utils::duration,
					    border => 24 );
  my $count = 0;
  while (my $row = $sth->fetchrow_hashref) {
    $count += $graph->add_row($row);
  }
  if ($count>0) {
    $graph->reorder('closed','long','10s','2s','1s','500ms','100ms');
    $png = new ReportLatency::AtomicFile("tags/summary/nreq_latency.png");
    print $png $graph->img()->png();
    close($png);
  }

  benchmark_point("nreq_latency.png");

  $sth = $qobj->nreq_response_histogram();
  $graph = new ReportLatency::StackedGraph( width => $histwidth,
					      height => $histheight,
					      duration => $ReportLatency::utils::duration,
					      border => 24 );
  $count = 0;
  while (my $row = $sth->fetchrow_hashref) {
    $count += $graph->add_row($row);
  }
  if ($count>0) {
    $graph->reorder('closed','500','400');

    $png = new ReportLatency::AtomicFile("tags/summary/nreq_error.png");
    print $png $graph->img()->png();
    close($png);
  }

  benchmark_point("nreq_error.png");

  $sth = $qobj->ureq_latency_histogram();
  $graph = new ReportLatency::StackedGraph( width => $histwidth,
					    height => $histheight,
					    duration => $ReportLatency::utils::duration,
					    border => 24 );
  $count = 0;
  while (my $row = $sth->fetchrow_hashref) {
    $count += $graph->add_row($row);
  }
  if ($count>0) {
    $graph->reorder('closed','long','10s','2s','1s','500ms','100ms');
    $png = new ReportLatency::AtomicFile("tags/summary/ureq_latency.png");
    print $png $graph->img()->png();
    close($png);
  }

  benchmark_point("ureq_latency.png");

  $sth = $qobj->ureq_response_histogram();
  $graph = new ReportLatency::StackedGraph( width => $histwidth,
					      height => $histheight,
					      duration => $ReportLatency::utils::duration,
					      border => 24 );
  $count = 0;
  while (my $row = $sth->fetchrow_hashref) {
    $count += $graph->add_row($row);
  }
  if ($count>0) {
    $graph->reorder('closed','500','400');

    $png = new ReportLatency::AtomicFile("tags/summary/ureq_error.png");
    print $png $graph->img()->png();
    close($png);
  }

  benchmark_point("ureq_error.png");
}

sub total_report {
  my ($view,$qobj,$options) = @_;
  my $html = new ReportLatency::AtomicFile("tags/summary/index.html");
  print $html $view->report_html($qobj);
  close($html);
}



sub main() {

  benchmark_start();

  my %options;
  my $r = GetOptions(\%options,
		     'help|?',
		     'man')
    or pod2usage(2);
  pod2usage(-verbose => 2) if $options{'man'};
  pod2usage(1) if $options{'help'};

  my $store = new ReportLatency::Store( dsn => latency_dsn('backup') );
  my $dbh = $store->{dbh};

  my $view = new ReportLatency::StaticView($store);

  my $t = time;
  my $begin = $store->db_timestamp($t - $ReportLatency::utils::duration);
  my $end = $store->db_timestamp($t);
  my $summary = new ReportLatency::Summary($store, $begin, $end);

  total_graph($summary);
  total_report($view,$summary,\%options);
  user_agents($store);
  extensions($store);

  $dbh->rollback() ||
    die "Unable to rollback, but there should be no changes anyway";

  benchmark_end();
}

main() unless caller();

__END__

=head1 NAME

summary.pl - generate summary total latency spectrum graphs and tables from a sqlite database

=head1 SYNOPSIS

cd data-dir

ls -l latency.sqlite3

cd ../www

summary.pl

 Options:
   -help      brief help message
   -man       full documentation

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

Part of the ReportLatency service, this script pre-generates expensive
graphs and tables of the full spectrum of latency reports over the past two
weeks.  Graph intensity is coded to green color brightness, and a red
average value.  The output is in the current directory, and the sqlite
database must be in ../data/latency.sqlite3 or
/var/lib/reportlatency/data/latency.sqlite3

=cut
