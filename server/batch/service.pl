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
use ReportLatency::StackedGraph;
use ReportLatency::StaticView;
use ReportLatency::Store;
use ReportLatency::Service;
use DBI;
use GD;
use Getopt::Long;
use Pod::Usage;
use strict;

my $days=14;


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


sub main() {

  my %options;
  my $r = GetOptions(\%options,
		     'help|?',
		     'man',
		     'verbose')
    or pod2usage(2);
  pod2usage(-verbose => 2) if $options{'man'};
  pod2usage(1) if $options{'help'};

  if ($options{'verbose'}) {
    benchmark_start();
  }

  my $store = new ReportLatency::Store( dsn => latency_dsn('backup') );

  my $view = new ReportLatency::StaticView($store);

  my $t = time;
  my $begin = $store->db_timestamp($t - $days * 24 * 3600);
  my $end = $store->db_timestamp($t);

  foreach my $service (all_services($store->{dbh})) {
    my $queries = new ReportLatency::Service($store, $begin, $end, $service);
    $view->realize($queries,"tags/$s");
  }

  if ($options{'verbose'}) {
    benchmark_end();
  }
}

main() unless caller();

__END__

=head1 NAME

service.pl - generate summary total latency spectrum graphs and tables from a sqlite database

=head1 SYNOPSIS

cd data-dir

ls -l latency.sqlite3

cd ../www

summary.pl

 Options:
   -help      brief help message
   -man       full documentation
   -verbose   steps and timings

=head1 OPTIONS

=over 8

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=item B<-verbose>

Time taken for each step of the batch job

=back

=head1 DESCRIPTION

Part of the ReportLatency service, this script pre-generates expensive
graphs and tables of the full spectrum of latency reports over the past two
weeks.  Graph intensity is coded to green color brightness, and a red
average value.  The output is in the current directory, and the sqlite
database must be in ../data/latency.sqlite3 or
/var/lib/reportlatency/data/latency.sqlite3

=cut
