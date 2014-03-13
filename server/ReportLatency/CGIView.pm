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

package ReportLatency::CGIView;
use parent 'ReportLatency::StaticView';

use strict;
use vars qw($VERSION);

$VERSION     = 0.1;

sub service_img_url {
  my ($self,$service) = @_;

  return "../../reportlatency/services/$service/navigation.png";
}

sub untagged_img_url {
  return "../../reportlatency/tags/untagged/navigation.png";
}

sub tag_img_url {
  my ($self,$tag) = @_;
  return "../../reportlatency/tags/$tag/navigation.png";
}

sub service_url {
  my ($self,$name) = @_;
  return "service?service=$name";
}

sub service_url_from_tag { return service_url(@_); }
sub service_url_from_location { return service_url(@_); }

sub tag_url {
  my ($self,$name) = @_;
  return "tag?name=$name";
}

sub location_url {
  my ($self,$name) = @_;
  return "location?name=$name";
}
sub location_url_from_tag { return location_url(@_); }

sub location_img_url {
  my ($self,$name) = @_;
  return "../../reportlatency/locations/$name/navigation.png";
}
1;


=pod

==head1 NAME

ReportLatency::CGIView - ReportLatency CGI view

=head1 VERSION

version 0.1

=head1 SYNOPSIS

use LatencyReport::CGIView

$view = new LatencyReport::CGIView($store);

=head1 DESCRIPTION

LatencyReport::CGIView accepts reports and produces measurements for
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
