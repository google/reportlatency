#
# Copyright 2014 Google Inc. All Rights Reserved.
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

package ReportLatency::AtomicFile;

use strict;
use vars qw($VERSION);
use parent 'File::Temp';
use File::Spec;
use Scalar::Util qw(reftype);

$VERSION     = 0.1;

my %realpath;

sub new {
  my $class = shift;
  my ($realpath) = shift;

  my ($vol,$dir,$fname) = File::Spec->splitpath($realpath);

  my $obj = $class->SUPER::new(DIR => $dir);

  $realpath{$obj} = $realpath;
  return $obj;
}

sub DESTROY {
  my $self = shift;
  my ($tmpfile) = $self->filename;
  my $realpath = $realpath{$self};
  delete $realpath{$self};

  # check for an overridden destructor...
  # $self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
  # now do your own thing before or after
  rename($tmpfile,$realpath);
}
1;

=pod

==head1 NAME

ReportLatency::AtomicFile - a filehandle where writes become live when closed

=head1 VERSION

version 0.1

=head1 SYNOPSIS

use ReportLatency::AtomicFile

my $file = new ReportLatency::AtomicFile($path)

=head1 DESCRIPTION

ReportLatency::AtomicFile directs all writes to a temporary file.  On
close, the temporary file is renamed atomicly to the desired filename.
The file is opened for write, the tempoary file is created.

=head1 USAGE

=head2 Methods

=head3 Constructors

=over 4
=item * ReportLatency::Store->new(path)

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
