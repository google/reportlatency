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

my $duration = $days * 86400;
my $interval = $hours * 3600;
my $border=24;

my $latency_ceiling = 30000; # 30s max for all icons


sub total_graph {
  my ($store,$options) = @_;

  my ($dbh) = $store->{dbh};
  my $sth = $store->total_nav_latencies_sth();

  my $latency_rc = $sth->execute('0 seconds', -$duration . " seconds");

  my $spectrum = new ReportLatency::Spectrum( width => $width,
					      height => $height,
					      duration => $duration,
					      ceiling => $latency_ceiling,
					      border => 24 );
  
  while (my $row = $sth->fetchrow_hashref) {
    $spectrum->add_row($row);
  }

  my $png = open_path("tags/summary/navigation.png");
  print $png $spectrum->png();
  close($png);

}

sub total_report {
  my ($view,$options) = @_;
  my $html = open_path("tags/summary/tmp-index.html");
  print $html $view->summary_html();
  close($html);
  rename("tags/summary/tmp-index.html","tags/summary/index.html");
}

sub service_report {
  my ($view,$name,$options) = @_;

  my $report = open_path("services/$name/tmp-index.html");
  print $report $view->service_html($name);
  close($report);
  rename("services/$name/tmp-index.html","services/$name/index.html");
}

sub tag_report {
  my ($view,$name,$options) = @_;

  my $report = open_path("tags/$name/tmp-index.html");
  print $report $view->tag_html($name);
  close($report);
  rename("tags/$name/tmp-index.html","tags/$name/index.html");
}

sub untagged_report {
  my ($view,$options) = @_;

  my $report = open_path("tags/untagged/tmp-index.html");
  print $report $view->untagged_html();
  close($report);
  rename("tags/untagged/tmp-index.html","tags/untagged/index.html");
}

sub service_graph {
  my ($store,$name,$options) = @_;

  my $dbh = $store->{dbh};
  my $sth = $store->service_nav_latencies_sth();

  my $latency_rc = $sth->execute($name, '0 seconds', -$duration . " seconds");
  my $spectrum = new ReportLatency::Spectrum( width => $width,
					      height => $height,
					      duration => $duration,
					      ceiling => $latency_ceiling,
					      border => 24 );
  
  while (my $row = $sth->fetchrow_hashref) {
    $spectrum->add_row($row);
  }

  my $png = open_path("services/$name/navigation.png");
  print $png $spectrum->png();
  close($png);
}

sub location_graph {
  my ($store,$name,$options) = @_;

  my $dbh = $store->{dbh};
  my $sth = $store->location_nav_latencies_sth();
  my $latency_rc = $sth->execute('0 seconds', -$duration . " seconds", $name);

  my $spectrum = new ReportLatency::Spectrum( width => $width,
					      height => $height,
					      duration => $duration,
					      ceiling => $latency_ceiling,
					      border => 24 );
  
  while (my $row = $sth->fetchrow_hashref) {
    $spectrum->add_row($row);
  }

  my $png = open_path("locations/$name/navigation.png");
  print $png $spectrum->png();
  close($png);
}

sub location_report {
  my ($view,$name,$options) = @_;

  my $report = open_path("locations/$name/tmp-index.html");
  print $report $view->location_html($name);
  close($report);
  rename("locations/$name/tmp-index.html","locations/$name/index.html");
}

sub recent_services {
  my ($dbh) = @_;

  my $services_sth =
      $dbh->prepare('SELECT DISTINCT service ' .
                    'FROM report ' .
                    "WHERE timestamp >= datetime('now',?) " .
		    "AND service IS NOT NULL " .
		    "ORDER BY service;")
        or die "prepare failed";

  my $services_rc = $services_sth->execute("-$interval seconds");

  my @services;
  while (my $row = $services_sth->fetchrow_hashref) {
    my $name = $row->{'service'};
    push(@services,$name);
  }
  @services;
}

sub recent_tags {
  my ($dbh) = @_;

  my $tags_sth =
      $dbh->prepare('SELECT DISTINCT tag.tag ' .
                    'FROM report ' .
		    'INNER JOIN tag ON tag.service=report.service ' .
                    "WHERE timestamp >= datetime('now',?);")
        or die "prepare failed";

  my $tags_rc = $tags_sth->execute("-$interval seconds");

  my @tags;
  while (my $row = $tags_sth->fetchrow_hashref) {
    my $name = $row->{'tag'};
    push(@tags,$name);
  }
  $tags_sth->finish;
  @tags;
}

sub recent_locations {
  my ($dbh) = @_;

  my $locations_sth =
      $dbh->prepare('SELECT DISTINCT location FROM report ' .
                    "WHERE timestamp >= datetime('now',?);")
        or die "prepare failed";

  my $locations_rc = $locations_sth->execute("-$interval seconds");

  my @locations;
  while (my $row = $locations_sth->fetchrow_hashref) {
    my $name = sanitize_location($row->{'location'});
    push(@locations,$name);
  }
  $locations_sth->finish;
  @locations;
}

sub all_services {
  my ($dbh) = @_;

  my $services_sth =
      $dbh->prepare('SELECT DISTINCT service ' .
                    'FROM report ' .
                    "WHERE service IS NOT NULL " .
		    "ORDER BY service;")
        or die "prepare failed";

  my $services_rc = $services_sth->execute();

  my @services;
  while (my $row = $services_sth->fetchrow_hashref) {
    my $name = $row->{'service'};
    push(@services,$name);
  }
  @services;
}

sub all_tags {
  my ($dbh) = @_;

  my $tags_sth =
      $dbh->prepare('SELECT DISTINCT tag FROM tag')
        or die "prepare failed";

  my $tags_rc = $tags_sth->execute();

  my @tags;
  while (my $row = $tags_sth->fetchrow_hashref) {
    my $tag = $row->{'tag'};
    push(@tags,$tag);
  }
  $tags_sth->finish;

  @tags;
}

sub all_locations {
  my ($dbh) = @_;

  my $locations_sth =
      $dbh->prepare('SELECT DISTINCT location ' .
                    'FROM report ' .
                    "WHERE location IS NOT NULL " .
		    "ORDER BY location;")
        or die "prepare failed";

  my $locations_rc = $locations_sth->execute();

  my @locations;
  while (my $row = $locations_sth->fetchrow_hashref) {
    my $name = sanitize_location($row->{'location'});
    push(@locations,$name);
  }
  @locations;
}

sub tag_graph {
  my ($store,$name,$options) = @_;

  my $dbh = $store->{dbh};
  my $sth = $store->tag_nav_latencies_sth;
  my $latency_rc = $sth->execute('0 seconds', -$duration . " seconds", $name);
  my $spectrum = new ReportLatency::Spectrum( width => $width,
					      height => $height,
					      duration => $duration,
					      ceiling => $latency_ceiling,
					      border => 24 );
  
  while (my $row = $sth->fetchrow_hashref) {
    $spectrum->add_row($row);
  }

  my $png = open_path("tags/$name/navigation.png");
  print $png $spectrum->png();
  close($png);
}

sub untagged_graph {
  my ($store,$options) = @_;

  my $dbh = $store->{dbh};
  my $sth = $store->untagged_nav_latencies_sth;
  my $latency_rc = $sth->execute('0 seconds', -$duration . " seconds");
  my $spectrum = new ReportLatency::Spectrum( width => $width,
					      height => $height,
					      duration => $duration,
					      ceiling => $latency_ceiling,
					      border => 24 );
  while (my $row = $sth->fetchrow_hashref) {
    $spectrum->add_row($row);
  }

 my $png = open_path("tags/untagged/navigation.png");
  print $png $spectrum->png();
  close($png);
}


sub main() {
  my %options;
  my $r = GetOptions(\%options,
		     'help|?',
		     'man',
		     'all')
    or pod2usage(2);
  pod2usage(-verbose => 2) if $options{'man'};
  pod2usage(1) if $options{'help'};

  my $dbh = latency_dbh('backup') || die "Unable to open db";
  $dbh->begin_work() || die "Unable to open transaction";
  my $store = new ReportLatency::Store( dbh => $dbh );
  my $view = new ReportLatency::StaticView($store);

  print "total\n";
  total_graph($store,\%options);
  total_report($view,\%options);

  print "untagged\n";
  untagged_graph($store,\%options);
  untagged_report($view,\%options);

  my (@services,@tags,@locations);
  if ($options{'all'}) {
    @services = all_services($dbh);
    @tags = all_tags($dbh);
    @locations = all_locations($dbh);
  } else {
    @services = recent_services($dbh);
    @tags = recent_tags($dbh);
    @locations = recent_locations($dbh);
  }

  foreach my $tag (@tags) {
    print "tag $tag\n";
    tag_graph($store,$tag,\%options);
    tag_report($view,$tag,\%options);
  }

  foreach my $location (@locations) {
    print "location " . ($location||'') . "\n";
    location_graph($store,$location,\%options);
    location_report($view,$location,\%options);
  }

  foreach my $service (@services) {
    print "service $service\n";
    service_graph($store,$service,\%options);
    service_report($view,$service,\%options);
  }

  $dbh->rollback() ||
    die "Unable to rollback, but there should be no changes anyway";
}

main() unless caller();

__END__

=head1 NAME

generate-static-content.pl - generate latency spectrum graphs and tables from a sqlite database

=head1 SYNOPSIS

cd data-dir

ls -l latency.sqlite3

cd ../graphs

generate-static-content.pl [-all]

 Options:
   -all       Generate all graphs, even if data is current
   -help      brief help message
   -man       full documentation

=head1 OPTIONS

=over 8

=item B<-all>

Generate all graphs adn tables, even if no new data has arrived.  Useful to
occaisionally catch up after and outage or to fill in recent blank
areas for inactive services.

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
