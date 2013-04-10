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

package ReportLatency::utils;
use Math::Round;
use Regexp::Common;


use base 'Exporter';
our @EXPORT    = qw(sanitize_service service_path mynum myround average
		    graphdir latency_dbh latency_summary_row);

sub graphdir { return '/var/lib/reportlatency/www/graph'; }

#
# All the CGI and batch scripts need the same database handle. Here it is.
# TODO: customize for different environments, allow overrides by local SA, etc.
#

sub latency_db_file() {
  foreach my $file ('/var/lib/reportlatency/data/latency.sqlite3',
		   '../data/latency.sqlite3') {
    if ((-r $file) && (-w $file)) {
      return $file;
    }
  }
}

sub latency_dbh() {
  my $dbfile = latency_db_file();
  $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile",
                      {AutoCommit => 0}, '')
    or die $dbh->errstr;
  return $dbh;
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
    if ($path =~ m%^/[a-z]+$%) {
      return "$domain$path";
    } else {
      return undef;
    }
  } else {
    return $domain;
  }
}

# used for pre-generated graphs, icons, etc
sub service_path($$) {
  my ($name,$ext) = @_;
  my $sane_name = sanitize_service($name) or return undef;
  return undef if ($name ne $sane_name);
  return "$name$ext";
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

sub latency_summary_row {
  my ($name,$url,$count,$row) = @_;

  my $html = "  <tr> <td align=left>";
  if (defined $name && $name ne '') {
    if (defined $url && $url ne '') {
      $html .= "<a href=\"$url\"> $name";
    } else {
      $html .= $name;
    }
  }
  $html .= ' </td>';
  $html .= "  <td align=right> $count </td> ";
  $html .=" <td align=right> " . mynum($row->{'request_count'}) . " </td>";
  $html .= " <td align=right> " . myround($row->{'request_latency'}) . " </td>";
  $html .= " <td align=right> " . mynum($row->{'tabupdate_count'}) . " </td>";
  $html .= " <td align=right> " . myround($row->{'tabupdate_latency'}) . " </td>";
  $html .= "   <td align=right> " . mynum($row->{'navigation_count'}) . " </td>";
  $html .= "   <td align=right> " . myround($row->{'navigation_latency'}) . " </td>";
  $html .= "  </tr>\n";
  return $html;
}

1;
