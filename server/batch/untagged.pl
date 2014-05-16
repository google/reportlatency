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
use ReportLatency::StaticView;
use ReportLatency::Store;
use DBI;
use GD;
use Getopt::Long;
use Pod::Usage;
use strict;

my $days=14;
my $hours=0.5;
my $width=$days*24/$hours;
my $height=int($width/2);

my $navwidth = $width;
my $navheight = $height;

my $reqwidth = 3*$width/4;
my $reqheight = 3*$height/4;

my $duration = $days * 86400;
my $interval = $hours * 3600;
my $border=24;

my $nav_ceiling = 30000; # 30s max for navigation images
my $nreq_ceiling = 30000; # 30s max for navigation request images
my $ureq_ceiling = 500000; # 300s max for update request images
my $req_floor = 10; # 30ms min for request images

sub untagged_report {
  my ($view,$options) = @_;

  my $report = new ReportLatency::AtomicFile("tags/untagged/index.html");
  print $report $view->untagged_html();
  close($report);
}

sub untagged_graph {
  my ($store,$options) = @_;

  my $dbh = $store->{dbh};
  my $sth = $store->untagged_nav_latencies_sth;
  my $latency_rc = $sth->execute(-$duration . " seconds", '0 seconds');
  my $spectrum = new ReportLatency::Spectrum( width => $navwidth,
					      height => $navheight,
					      duration => $duration,
					      ceiling => $nav_ceiling,
					      border => 24 );
  while (my $row = $sth->fetchrow_hashref) {
    $spectrum->add_row($row);
  }

  my $png = new ReportLatency::AtomicFile("tags/untagged/navigation.png");
  print $png $spectrum->png();
  close($png);


  $sth = $store->untagged_nreq_latencies_sth();

  $latency_rc = $sth->execute(-$duration . " seconds", '0 seconds');

  $spectrum = new ReportLatency::Spectrum( width => $reqwidth,
					   height => $reqheight,
					   duration => $duration,
					   ceiling => $nreq_ceiling,
					   floor   => $req_floor,
					   border => 24 );

  while (my $row = $sth->fetchrow_hashref) {
    $spectrum->add_row($row);
  }

  $png = new ReportLatency::AtomicFile("tags/untagged/nav_request.png");
  print $png $spectrum->png();
  close($png);


  $sth = $store->untagged_ureq_latencies_sth();

  $latency_rc = $sth->execute(-$duration . " seconds", '0 seconds');

  $spectrum = new ReportLatency::Spectrum( width => $reqwidth,
					   height => $reqheight,
					   duration => $duration,
					   ceiling => $ureq_ceiling,
					   floor   => $req_floor,
					   border => 24 );

  while (my $row = $sth->fetchrow_hashref) {
    $spectrum->add_row($row);
  }

  $png = new ReportLatency::AtomicFile("tags/untagged/update_request.png");
  print $png $spectrum->png();
  close($png);
}


sub main() {
  my %options;
  my $r = GetOptions(\%options,
		     'help|?',
		     'man')
    or pod2usage(2);
  pod2usage(-verbose => 2) if $options{'man'};
  pod2usage(1) if $options{'help'};

  my $store = new ReportLatency::Store( dsn => latency_dsn('backup') );
  my $dbh = $store->{dbh};
  $dbh->begin_work() || die "Unable to open transaction";

  my $view = new ReportLatency::StaticView($store);

  untagged_graph($store,\%options);
  untagged_report($view,\%options);

  $dbh->rollback() ||
    die "Unable to rollback, but there should be no changes anyway";
}

main() unless caller();

__END__

=head1 NAME

untagged.pl - generate the untagged latency report from a sqlite database

=head1 SYNOPSIS

cd data-dir

ls -l latency.sqlite3

cd ../www

untagged.pl

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
