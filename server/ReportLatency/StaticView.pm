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

package ReportLatency::StaticView;

use strict;
use vars qw($VERSION);
use ReportLatency::utils;
use IO::String;
use URI::Escape;
use Data::Dumper;

$VERSION     = 0.2;

sub new {
  my $class = shift;
  my ($store) = @_;

  my $self  = bless {}, $class;

  $self->{store} = $store;

  return $self;
}

sub tag_img_prefix {
  my ($self,$tag) = @_;
  return "";
}

sub tag_img_url {
  my ($self,$tag) = @_;
  return "navigation.png";
}

sub tag_nreq_img_url {
  my ($self,$tag) = @_;
  return "nav_request.png";
}

sub tag_ureq_img_url {
  my ($self,$tag) = @_;
  return "update_request.png";
}

sub useragents_url {
  my ($self,$tag) = @_;
  return "useragents.png";
}

sub extensions_url {
  my ($self,$tag) = @_;
  return "extensions.png";
}

sub tag_url {
  my ($self,$tag) = @_;
  return "../$tag/index.html";
}

sub untagged_url {
  my ($self,$tag) = @_;
  return "../untagged/index.html";
}

sub untagged_img_url {
  return "navigation.png";
}

sub service_url_from_tag {
  my ($self,$name) = @_;
  return "../../services/$name/index.html";
}

sub service_url_from_location {
  my ($self,$name) = @_;
  return "../../services/$name/index.html";
}

sub location_url {
  my ($self,$name) = @_;
  return "$name/index.html";
}

sub location_img_url {
  my ($self,$name) = @_;
  return "navigation.png";
}

sub location_nreq_img_url {
  my ($self,$name) = @_;
  return "nav_request.png";
}

sub location_ureq_img_url {
  my ($self,$name) = @_;
  return "update_request.png";
}

sub location_url_from_tag {
  my ($self,$name) = @_;
  return "../../locations/" . $self->location_url($name);
}

sub common_header_1 {
  my ($self) = @_;
  return <<EOF;
 <th colspan=8> Navigation </th>
 <th colspan=8> Navigation Request </th>
 <th colspan=7> Update Request </th>
EOF
}

sub common_header_2 {
  my ($self) = @_;
  return <<EOF;
 <th>200</th> <th>300</th> <th>400</th> <th>500</th> <th>closed</th> <th>count</th> <th>latency</th> <th>avail</th>
 <th>200</th> <th>300</th> <th>400</th> <th>500</th> <th>closed</th> <th>count</th> <th>latency</th> <th>avail</th>
 <th>200</th> <th>300</th> <th>400</th> <th>500</th> <th>count</th> <th>latency</th> <th>avail</th>
EOF
}

sub availability {
  my ($self,$type,$row) = @_;

  my $count = ($row->{$type . "_count"} || 0);
  my $r200 = ($row->{$type . "_200"} || 0);
  my $r300 = ($row->{$type . "_300"} || 0);
  my $r400 = ($row->{$type . "_400"} || 0);
  my $r500 = ($row->{$type . "_500"} || 0);
  my $closed = ($row->{$type . "_tabclosed"} || 0);
  my $denom = $r200 + $r400 + $r500 + $closed;
  if ($denom > 0) {
    return $r200 / $denom;
  } else {
    return undef;
  }
}

sub percentage {
  my ($self,$fraction) = @_;
  if (defined $fraction) {
    return int(10000*$fraction)/100 . '%';
  }
  return '';
}

sub common_html_fields {
  my ($self,$row) = @_;
  return
    " <td align=right> " . mynum($row->{'nav_200'}) . " </td>" .
    " <td align=right> " . mynum($row->{'nav_300'}) . " </td>" .
    " <td align=right> " . mynum($row->{'nav_400'}) . " </td>" .
    " <td align=right> " . mynum($row->{'nav_500'}) . " </td>" .
    " <td align=right> " . mynum($row->{'nav_tabclosed'}) . " </td>" .
    " <td align=right> " . mynum($row->{'nav_count'}) . " </td>" .
    ' <td align=right class="latency"> ' . myround($row->{'nav_latency'}) .
      " </td>" .
    ' <td align=right class="avail"> ' .
      $self->percentage($self->availability('nav',$row)) . ' </td>' .
    " <td align=right> " . mynum($row->{'nreq_200'}) . " </td>" .
    " <td align=right> " . mynum($row->{'nreq_300'}) . " </td>" .
    " <td align=right> " . mynum($row->{'nreq_400'}) . " </td>" .
    " <td align=right> " . mynum($row->{'nreq_500'}) . " </td>" .
    ' <td align=right> ' . mynum($row->{'nreq_tabclosed'}) . " </td>" .
    " <td align=right> " . mynum($row->{'nreq_count'}) . " </td>" .
    ' <td align=right class="latency"> ' . myround($row->{'nreq_latency'}) .
      " </td>" .
    ' <td align=right class="avail"> ' .
      $self->percentage($self->availability('nreq',$row)) . ' </td>' .
    " <td align=right> " . mynum($row->{'ureq_200'}) . " </td>" .
    " <td align=right> " . mynum($row->{'ureq_300'}) . " </td>" .
    " <td align=right> " . mynum($row->{'ureq_400'}) . " </td>" .
    " <td align=right> " . mynum($row->{'ureq_500'}) . " </td>" .
    " <td align=right> " . mynum($row->{'ureq_count'}) . " </td>" .
    ' <td align=right class="latency"> ' . myround($row->{'ureq_latency'}) .
      " </td>" .
    ' <td align=right class="avail"> ' .
      $self->percentage($self->availability('ureq',$row)) . ' </td>';
}

sub name_value_row {
  my ($self,$row) = @_;
  my $name = $row->{name};
  my $value = $row->{value};
  my $html = "  <tr> <td align=left>$name</td> <td align=right>$value</td> </tr>\n";
  return $html;
}


sub latency_summary_row {
  my ($self,$name,$url,$count,$row) = @_;
#  my $sname = sanitize_service($name);
  my $sname = $name;

  my $html = "  <tr> <td align=left>";
  if (defined $sname && $sname ne '') {
    if (defined $url && $url ne '') {
      $html .= "<a href=\"$url\"> $sname </a> ";
    } else {
      $html .= $sname;
    }
  }
  $html .= ' </td>';
  $html .= " <td align=right> $count </td> ";
  $html .= $self->common_html_fields($row);
  $html .= "  </tr>\n";
  return $html;
}

sub alternate_style {
  my ($self) = @_;
  return <<EOF;
    table.alternate tr:nth-child(odd) td{ background-color: #CCFFCC; }
    table.alternate tr:nth-child(even) td{ background-color: #99DD99; }
    table.alternate tr td.latency{ font-weight:bold; }
    table.alternate tr td.avail{ font-weight:bold; }
    table.alternate tr th{ background-color: #DDDDDD; }
EOF
}

sub dual_column_style {
  my ($self) = @_;
  return <<EOF;
#left_column {
   float:left;
   width:50%;
}
#right_column {
   float:left;
   width:50%;
}
#nav {
   float:left;
   width:33%;
}
#nreq {
   float:left;
   width:33%;
}
#ureq {
   float:right;
   width:33%;
}

EOF
}

sub image_banner {
  my ($self,$img_prefix) = @_;
  return <<EOF
<div id="nav">
  <p>
    <img src="${img_prefix}nav_latency.png" width="95%" alt="navigation latency spectrum">
  </p>
  <p>
    <img src="${img_prefix}nav_error.png" width="95%" alt="navigation errors over time">
  </p>
  <p>
    <img src="${img_prefix}nav_spectrum.png" width="95%" alt="navigation latency spectrum">
    <br>
    Navigation (Pageload)
  </p>
</div>
<div id="nreq">
  <p>
    <img src="${img_prefix}nreq_latency.png" width="95%" alt="nav request latency">
  </p>
  <p>
    <img src="${img_prefix}nreq_error.png" width="95%" alt="navigation request errors over time">
  </p>
  <p>
    <img src="${img_prefix}nreq_spectrum.png" width="95%" alt="navigation request latency spectrum">
    <br>
    Requests during navigation
  </p>
</div>
<div id="ureq">
  <p>
    <img src="${img_prefix}ureq_latency.png" width="95%" alt="update request latency">
  </p>
  <p>
    <img src="${img_prefix}ureq_error.png" width="95%" alt="update request errors over time">
  </p>
  <p>
    <img src="${img_prefix}ureq_spectrum.png" width="95%" alt="update request latency spectrum">
    <br>
    Requests after navigation
  </p>
</div>
EOF
}


sub report_html {
  my ($self,$qobj) = @_;

  benchmark_point("start report_html()");
  my $meta = $qobj->meta();
  benchmark_point("meta()");
  my $tag_sth = $qobj->tag();
  benchmark_point("tag_sth opened()");
  my $location_sth = $qobj->location();
  benchmark_point("location_sth opened()");

  my $image_prefix = $self->tag_img_prefix('summary');

  my $begin = $meta->{'min_timestamp'};
  my $end = $meta->{'max_timestamp'};

  my $io = new IO::String;

  my $header_1 = $self->common_header_1();
  my $header_2 = $self->common_header_2();
  my $altstyle = $self->alternate_style();
  my $twostyle = $self->dual_column_style();
  my $image_banner = $self->image_banner($image_prefix);

  my $tag_header = <<EOF;
<tr>
 <th colspan=2> Tag </th>
$header_1
</tr>
<tr>
 <th>Name</th> <th>Services</th>
$header_2
</tr>
EOF

  print $io <<EOF;
<!DOCTYPE html>
<html>
<head>
  <title>ReportLatency summary</title>
  <style type="text/css">
$altstyle
$twostyle
  </style>
</head>
<body>

<h1> ReportLatency Summary </h1>
$image_banner

<table class="alternate" summary="Latency report for all services by tag">
$tag_header
EOF

  benchmark_point("start tag_sth");
  while (my $tag = $tag_sth->fetchrow_hashref) {
    my $name = $tag->{tag};
    my $url = $self->tag_url($name);
    my $count = $tag->{'services'};
    print $io $self->latency_summary_row($name,$url,$count,$tag);
  }
  $tag_sth->finish;
  benchmark_point("end tag_sth");

  print $io $tag_header;

  print $io $self->latency_summary_row('total', '',
				       $meta->{'services'}, $meta);

  print $io <<EOF;
</table>

EOF

  my $location_header = <<EOF;
<tr>
 <th colspan=2> Location </th>
$header_1
</tr>
<tr>
 <th>Name</th> <th>Services</th>
$header_2
</tr>
EOF

  print $io <<EOF;
<h2> Latency By Location </h2>

<table class="alternate" summary="Latency report for all services by location">
$location_header
EOF

  benchmark_point("start location_sth");
  while (my $location = $location_sth->fetchrow_hashref) {
    my $name = $location->{location};
    my $url = $self->location_url_from_tag(uri_escape($name));
    my $count = $location->{'services'};
    print $io $self->latency_summary_row(sanitize_location($name),$url,
					 $count,$location);
  }
  $location_sth->finish;
  benchmark_point("end location_sth");

  print $io <<EOF;
</table>


<h2> Client Summary </h2>
    <div id="left_column">
<img src="${image_prefix}useragents.png" alt="user_agent distribution over time"><br>
      <table class="alternate" summary="Distribution of User Agents">
        <tr> <th>User Agent</th> <th>Uploads</th> </tr>
EOF

  benchmark_point("start user_agent_sth");
  my $user_agent_sth = $qobj->user_agent;
  while (my $ua = $user_agent_sth->fetchrow_hashref) {
    print $io $self->name_value_row($ua);
  }
  $user_agent_sth->finish;

  benchmark_point("end user_agent_sth");

print $io <<EOF;
      </table>
    </div>
    <div id="right_column">
<img src="${image_prefix}extensions.png" alt="Distribution of User Agents over time"><br>
      <table class="alternate" summary="Distribution of User Agents (browsers)">
        <tr> <th>Extension Version</th> <th>Uploads</th> </tr>
EOF

  benchmark_point("start extension_version_sth");
  my $extension_version_sth = $qobj->extension_version;
  while (my $v = $extension_version_sth->fetchrow_hashref) {
    print $io $self->name_value_row($v);
  }
  $extension_version_sth->finish;

  benchmark_point("end extension_version_sth");

print $io <<EOF;
      </table>
    </div>
EOF

  print $io meta_timestamp_html($meta);

  print $io <<EOF;
</body>
</html>
EOF

  benchmark_point("end report_html()");

  $io->setpos(0);
  return ${$io->string_ref};
}

sub untagged_html {
  my ($self) = @_;
  my $store = $self->{store};

  my $meta_sth = $store->untagged_meta_sth;
  my $rc = $meta_sth->execute();
  my $meta = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  my $service_sth = $store->untagged_service_sth;
  $rc = $service_sth->execute($meta->{'min_timestamp'},
			      $meta->{'max_timestamp'});


  my $io = new IO::String;

  my $service_header = <<EOF;
EOF

  my $nav_img_url = $self->untagged_img_url;
  my $nreq_img_url = $self->tag_nreq_img_url('untagged');
  my $ureq_img_url = $self->tag_ureq_img_url('untagged');

  my $image_banner = $self->image_banner($nav_img_url,$nreq_img_url,
					 $ureq_img_url);
  my $header_1 = $self->common_header_1();
  my $header_2 = $self->common_header_2();
  my $altstyle = $self->alternate_style();
  my $twostyle = $self->dual_column_style();

  print $io <<EOF;
<!DOCTYPE html>
<html>
<head>
  <title>Latency report for untagged services</title>
  <style type="text/css">
$altstyle
$twostyle
  </style>
</head>
<body>

<h1> Latency Summary For Untagged Services </h1>
$image_banner

<table class="alternate" summary="Latency report for untagged services">
<tr>
 <th colspan=2> Service </th>
$header_1
</tr>
<tr>
 <th>Name</th> <th>Dependencies</th>
$header_2
</tr>
EOF

  while (my $service = $service_sth->fetchrow_hashref) {
    my $name = $service->{service};
    if (defined $name) {
      my $url = $self->service_url_from_tag($name);
      my $count = $service->{'dependencies'};
      print $io $self->latency_summary_row($name,$url,$count,$service);
    }
  }
  $service_sth->finish;

  print $io <<EOF;
<tr>
 <th> Service </th>
 <th> Service </th>
$header_1
</tr>
<tr>
 <th></th> <th>Count</th>
$header_2
</tr>
EOF

  print $io $self->latency_summary_row('total', '',
				       $meta->{'services'}, $meta);

  print $io <<EOF;
</table>

EOF

  print $io meta_timestamp_html($meta);

  print $io <<EOF;

</body>
</html>
EOF

  $io->setpos(0);
  return ${$io->string_ref};
}



sub location_html {
  my ($self,$loc) = @_;

  my $store = $self->{store};

  my $unescape = uri_unescape($loc);
  my $location = sanitize_location($unescape);

  my $io = new IO::String;

  my $meta_sth = $store->location_meta_sth;
  my $service_sth = $store->location_service_sth;

  my $rc = $meta_sth->execute($location);
  my $meta = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  my $nav_img_url = $self->location_img_url($location);
  my $nreq_img_url = $self->location_nreq_img_url($location);
  my $ureq_img_url = $self->location_ureq_img_url($location);
  my $image_banner = $self->image_banner($nav_img_url,$nreq_img_url,
					 $ureq_img_url);

  my $service_header = <<EOF;
EOF

  my $header_1 = $self->common_header_1();
  my $header_2 = $self->common_header_2();
  my $altstyle = $self->alternate_style();
  my $twostyle = $self->dual_column_style();

  my $title = 'Location ' . ($location||'');
  print $io <<EOF;
<!DOCTYPE html>
<html>
<head>
  <title>Latency Summary For $title</title>
  <style type="text/css">
$altstyle
$twostyle
  </style>
</head>
<body>

<h1> Latency Summary For $title </h1>

$image_banner

<table class="alternate" summary="Latency report for all services at $title">
<tr>
 <th colspan=2> Service </th>
$header_1
</tr>
<tr>
 <th>Name</th> <th>Dependencies</th>
$header_2
</tr>
EOF

  $rc = $service_sth->execute($meta->{'min_timestamp'},
			      $meta->{'max_timestamp'},$location);

  while (my $service = $service_sth->fetchrow_hashref) {
    my $name = sanitize_service($service->{service});
    if (defined $name) {
      my $url = $self->service_url_from_location($name);
      my $count = $service->{'dependencies'};
      print $io $self->latency_summary_row($name,$url,$count,$service);
    }
  }
  $service_sth->finish;

  print $io <<EOF;
<tr>
 <th> Service </th>
 <th> Service </th>
$header_1
</tr>
<tr>
 <th></th> <th>Count</th>
$header_2
</tr>
EOF

  print $io $self->latency_summary_row('total', '',
				       $meta->{'services'}, $meta);

  print $io <<EOF;
</table>
EOF

  print $io meta_timestamp_html($meta);
                      
print $io <<EOF;
</body>
</html>
EOF

  $io->setpos(0);
  return ${$io->string_ref};
}


sub service_img_url {
  my ($self,$service) = @_;
  return 'navigation.png';
}

sub service_nreq_img_url {
  my ($self,$service) = @_;
  return 'nav_request.png';
}

sub service_ureq_img_url {
  my ($self,$service) = @_;
  return 'update_request.png';
}


sub service_not_found($$) {
  my ($self,$name) = @_;

  my $io = new IO::String;

  print $io <<EOF;
<!DOCTYPE html>
<html>
<body>
<h1> Latency Report </h1>

No recent reports were found for $name
</body>
</html>
EOF
  $io->setpos(0);
  return ${$io->string_ref};
}

sub service_found {
  my ($self,$service,$meta_sth,$select,$select_location) = @_;

  my $io = new IO::String;


  my $rc = $meta_sth->execute($service);
  my $meta = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  if (! $meta) {
    return $self->service_not_found($service);
  }

  my $nav_img_url = $self->service_img_url($service);
  my $nreq_img_url = $self->service_nreq_img_url($service);
  my $ureq_img_url = $self->service_ureq_img_url($service);
  my $image_banner = $self->image_banner($nav_img_url,$nreq_img_url,
					 $ureq_img_url);

  my $header_1 = $self->common_header_1();
  my $header_2 = $self->common_header_2();
  my $altstyle = $self->alternate_style();
  my $twostyle = $self->dual_column_style();

  print $io <<EOF;
<!DOCTYPE html>
<html>
<head>
  <style type="text/css">
$altstyle
$twostyle
  </style>
  <title> $meta->{'date'} $service Latency </title>
</head>
<body>

<h1> $service $meta->{'date'} Latency Report </h1>
$image_banner

<h2> All locations, each request name </h2>

<table class="alternate" summary="$service latency by request name">
<tr>
 <th rowspan=2> Request Name</th>
$header_1
</tr>
<tr>
$header_2
</tr>
EOF

  $rc = $select->execute($service);

  while ( my $row = $select->fetchrow_hashref) {
    my $name = sanitize_service($row->{'name'}) or next;
    print $io "  <tr>";
    print $io " <td> $name </td>";
    print $io $self->common_html_fields($row);
    print $io "  </tr>\n";
  }
  $select->finish;

  print $io <<EOF;
<tr>
 <th rowspan=2> Request Name</th>
$header_1
</tr>
<tr>
$header_2
</tr>
<tr> <td align=center> total </td>
EOF
  print $io $self->common_html_fields($meta);
  print $io <<EOF;
</tr>
</table>

<h2> Each location, names aggregated </h2>

<table class="alternate" summary="$service latency by location">
<tr>
 <th rowspan=2> Location </th>
$header_1
</tr>
<tr>
$header_2
</tr>
EOF

  $rc = $select_location->execute($service);
  while ( my $row = $select_location->fetchrow_hashref) {
    my $location = $row->{'location'} || 'N/A';
    print $io "  <tr>";
    print $io " <td> $location </td>";
    print $io $self->common_html_fields($row);
    print $io "  </tr>\n";
  }
  $select_location->finish;

  print $io <<EOF;
</table>

EOF

  print $io meta_timestamp_html($meta);

  print $io <<EOF;

</body>
</html>
EOF

  $io->setpos(0);
  return ${$io->string_ref};
}

sub meta_timestamp_html {
  my ($meta) = @_;
  my $min_t = $meta->{'min_timestamp'} || '';
  my $max_t = $meta->{'max_timestamp'} || '';

  return <<EOF;
<p>
Timespan: $min_t through $max_t
</p>
EOF
}

sub service_html {
  my ($self,$svc) = @_;
  my $store = $self->{store};
  my $dbh = $store->{dbh};

  my $service_name = sanitize_service($svc);

  my $io = new IO::String;

  my $meta_sth = $store->service_meta_sth;
  my $select_sth = $store->service_select_sth;
  my $select_location_sth = $store->service_location_sth;

  return $self->service_found($service_name,$meta_sth,$select_sth,
			      $select_location_sth);
}

sub tag_html {
  my ($self,$tag) = @_;
  my $store = $self->{store};

  my $tag_name = sanitize($tag);
  my $nav_img_url = $self->tag_img_url($tag_name);
  my $nreq_img_url = $self->tag_nreq_img_url($tag_name);
  my $ureq_img_url = $self->tag_ureq_img_url($tag_name);
  my $image_banner = $self->image_banner($nav_img_url,$nreq_img_url,
					 $ureq_img_url);

  my $meta_sth = $store->tag_meta_sth;
  my $service_sth = $store->tag_service_sth;


  my $rc = $meta_sth->execute($tag);
  my $meta = $meta_sth->fetchrow_hashref;
  $meta_sth->finish;

  my $io = new IO::String;

  my $service_header = <<EOF;
EOF

  my $header_1 = $self->common_header_1();
  my $header_2 = $self->common_header_2();
  my $altstyle = $self->alternate_style();
  my $twostyle = $self->dual_column_style();

  print $io <<EOF;
<!DOCTYPE html>
<html>
<head>
  <title>$tag_name ReportLatency summary</title>
  <style type="text/css">
$altstyle
$twostyle
  </style>
</head>
<body>

<h1> Latency Summary For Tag $tag_name </h1>
$image_banner

<table class="alternate" summary="Latency report for $tag_name services">
<tr>
 <th colspan=2> Service </th>
$header_1
</tr>
<tr>
 <th>Name</th> <th>Dependencies</th>
$header_2
</tr>
EOF

  $rc = $service_sth->execute($meta->{'min_timestamp'},
			      $meta->{'max_timestamp'},$tag_name);

  while (my $service = $service_sth->fetchrow_hashref) {
    my $name = sanitize_service($service->{service});
    if (defined $name) {
      my $url = $self->service_url_from_tag($name);
      my $count = $service->{'dependencies'};
      print $io $self->latency_summary_row(sanitize_service($name),$url,$count,
					   $service);
    }
  }
  $service_sth->finish;

  print $io <<EOF;
<tr>
 <th> Service </th>
 <th> Service </th>
$header_1
</tr>
<tr>
 <th></th> <th>Count</th>
$header_2
</tr>
EOF

  print $io $self->latency_summary_row('total', '',
				       $meta->{'services'}, $meta);

  print $io <<EOF;
</table>
                      
</body>
</html>
EOF
  $io->setpos(0);
  return ${$io->string_ref};
}

sub realize {
  my ($self,$qobj,$dir) = @_;
  my $html = new ReportLatency::AtomicFile("$dir/index.html");
  print $html $self->report_html($qobj);
  close($html);
}

1;


=pod

==head1 NAME

ReportLatency::Store - Storage object for ReportLatency data

=head1 VERSION

version 0.1

=head1 SYNOPSIS

use LatencyReport::Store

$store = new LatencyReport::Store(
  dbh => $dbh
);

=head1 DESCRIPTION

LatencyReport::Store accepts reports and produces measurements for
table and spectrum generation.  The storage is in a database,
typically sqlite3 or syntactically compatible.

=head1 USAGE

=head2 Methods

=head3 Constructors

=over 4
=item * LatencyReport::Store->new(...)

=over 8

=item * dbh

The database handle for the sqlite3 or compatible database that should
be used for real storage by this object.  The schema must already be present.

=head3 Member functions

=over 4
=item * post(CGI)
=over 8
  Parse a CGI request object for latency report data and
  insert it into the database.

=head1 KNOWN BUGS

=head1 SUPPORT

=head1 SEE ALSO

=head1 AUTHOR

Drake Diedrich <dld@google.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright Google Inc.  All Rights Reserved.

This is free software, licensed under:

  The Apache 2.0 License

=cut
