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

package ReportLatency::utils;
use DBI;
use HTML::Scrubber;
use Math::Round;
use Regexp::Common;
use Net::DNS::Resolver;
use File::Path qw(make_path);
use File::Spec;

use base 'Exporter';
our @EXPORT    = qw(sanitize sanitize_service sanitize_location service_path
		    mynum myround average
		    open_path
		    latency_dbh net_class_c
		    reverse_dns aggregate_user_agent);

#
# All the CGI and batch scripts need the same database handle. Here it is.
# TODO: customize for different environments, allow overrides by local SA, etc.
#

our %dbh;
$dbh{'latency'} = ReportLatency::utils::latency_dbh();

sub config_file {
  my $file = $ENV{'REPORTLATENCY_CONFIG_FILE'} || "/etc/reportlatency.conf";
  if (-e $file) {
    do $file;
    die $@ if $@;
    return 1;
  }
  return;
}

config_file();

sub latency_db_file {
  my ($role) = @_;
  $role = 'latency' unless defined $role;
  foreach my $file ("data/$role.sqlite3",
		    "/var/lib/reportlatency/data/$role.sqlite3",
		   "../data/$role.sqlite3") {
    if ((-r $file) && (-w $file)) {
      return $file;
    }
  }
}

sub latency_dbh {
  my ($role) = @_;
  $role = 'latency' unless defined $role;
  if (! defined $dbh{$role}) {
    my $dbfile = latency_db_file($role);
    if ($dbfile) {
      $dbh{$role} = DBI->connect("dbi:SQLite:dbname=$dbfile",
			  {AutoCommit => 0, RaiseError => 1}, '')
	or die $dbh{$role}->errstr;
    }
  }
  $dbh{$role};
}

#
# only allow host/domain names as service names
#
my $domain_re = $RE{net}{domain};
sub sanitize_service($) {
  my ($service) = @_;
  my ($domain,$path);
  return undef unless defined $service;
  if ($service eq '.') {
    $domain = '.';
  } elsif ($service =~ /^($domain_re)(.*)/) {
    $domain = $1;
    $path = $2;
  } else {
    return undef;
  }
  if ($path) {
    if ($path =~ m%^/[A-Za-z][A-Za-z0-9]*$%) {
      return "$domain$path";
    } else {
      return undef;
    }
  } else {
    return $domain;
  }
}

my $ipv4_re = $RE{net}{IPv4};
sub sanitize_location {
  my ($location) = @_;
  return undef unless defined $location;
  if ($location =~/^($ipv4_re)$/) {
    return $location;
  } elsif ($location =~ /^($domain_re\.)(.*)/) {
    my $domain = $1;
    my $rest = $2;
    if ($rest =~ /^\s+[A-Za-z0-9]+$/) {
      return "$domain$rest";
    } else {
      return $domain;
    }
  } else {
    return undef;
  }
}

my $scrubber = HTML::Scrubber->new(allow => [ qw[ b i u ] ]);
sub sanitize {
  my ($str) = @_;
  return undef unless defined $str;
  return undef if $str eq '';
  my $scrubbed = $scrubber->scrub($str);
  return undef unless $scrubbed eq $str;
  return $scrubbed;
}
  
# used for pre-generated graphs, icons, etc
sub service_path($$) {
  my ($name,$ext) = @_;
  my $sane_name = sanitize_service($name) or return undef;
  return undef if ($name ne $sane_name);
  return "$name$ext";
}

sub open_path($) {
  my ($path) = @_;
  my ($volume,$directories,$file) = File::Spec->splitpath( $path );
  if (! -d $directories ) {
    make_path $directories;
  }
  open(my $fh,">",$path) || die "$!: unable to open $path";
  return $fh;
}


sub mynum($) {
  my ($x) = @_;
  return $x if (defined $x);
  "";
}

sub myround($) {
  my ($x) = @_;
  return round($x) if (defined $x);
  "";
}

sub average($$) {
  my ($total,$count) = @_;
  if (defined $total && defined $count && $count>=1) {
    return round($total/$count);
  }
  "";
}

sub net_class_c($) {
  my ($ip) = @_;
  if ($ip =~ /^(\d+)\.(\d+)\.(\d+).(\d+)$/) {
    return "$1.$2.$3.0";
  }
  return undef;
}


sub ip_to_arpa {
  my ($ip) = @_;
  my $arpa = join('.', reverse split(/\./, $ip)) . ".in-addr.arpa";
  return $arpa;
}

sub reverse_dns {
  my ($ip) = @_;
  my $arpa = ip_to_arpa($ip);
  my $res = new Net::DNS::Resolver;
  my $query = $res->query($arpa, 'PTR');
  if ($query) {
    foreach my $rr ($query->answer) {
      next unless $rr->type eq 'PTR';
      return $rr->rdatastr;
    }
  }
  undef;
}

sub aggregate_user_agent($) {
  my ($browser) = @_;

  if ($browser =~ /Chrome\/(\d+)/) {
    return "Chrome $1";
  }

  if ($browser =~ /(Firefox|Gecko\/)/) {
    return "Firefox";
  }

  if ($browser =~ /Safari\//) {
    return "Safari";
  }

  if ($browser =~ /IE/) {
    return "IE";
  }

  return "Other";
}

sub path_depth($) {
  my ($path) = @_;
  my ($count) = 0;
  my (@component) = split('/',$path);
  foreach my $c (@component) {
    if ($c eq '.') {
      next;
    } elsif ($c eq '..') {
      $count--;
    } else {
      $count++;
    }
  }
  return $count;
}


1;
