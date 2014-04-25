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

package ReportLatency::StackedGraph;

use strict;
use Date::Calc qw(Time_to_Date Date_to_Time);
use GD::Graph::area;
use Math::Round;
use vars qw($VERSION);

$VERSION     = 0.1;

sub new {
  my $class = shift;
  my %p = @_;

  $p{width} = 1000 unless exists $p{width};
  $p{height} = 250 unless exists $p{height};
  $p{duration} = 14 * 24 * 3600 unless exists $p{duration};
  $p{border} = 0 unless exists $p{border};

  my $self  = bless {}, $class;

  foreach my $param (qw( width height border duration )) {
    $self->{$param} = $p{$param};
  }

  $self->{data} = {};

  return $self;
}

sub width {
  my ($self) = @_;
  return $self->{width};
}

sub height {
  my ($self) = @_;
  return $self->{height};
}

sub duration {
  my ($self) = @_;
  return $self->{duration};
}

sub maxval {
  my ($self) = @_;
  return $self->{maxval};
}

sub duration_end {
  return time;
}

sub duration_begin {
  my ($self) = @_;
  return time - $self->{duration};
}

sub _x {
  my ($self,$timestamp) = @_;
  my $x = $self->{width} -1
    - round(($self->duration_end - $timestamp) *
	    $self->{width} / $self->duration);
  return undef if ($x<0);
  return $x;
}

sub add {
  my ($self,$timestamp,$measure,$amount) = @_;
  if ($amount>0) {
    my $x = $self->_x($timestamp);
    if (defined $x) {
      if (! defined $self->{data}{$measure}) {
	$self->{data}{$measure} = [];
	foreach my $i (0..$self->width-1) {
	  $self->{data}{$measure}[$i] = 0;
	}
      }
      $self->{data}{$measure}[$x] += $amount;
      return $self->{data}{$measure}[$x];
    }
  }
  undef;
}

sub add_row {
  my ($self,$row) = @_;
  my $points=0;

  my $timestamp = $row->{'timestamp'};
  my $measure = $row->{'measure'};
  my $amount = $row->{'amount'};
  return $self->add($timestamp, $measure, $amount);
}


sub _label_days {
  my ($self) = @_;
  $self->{xlabel} = [];
  for (my $i=0;$i<$self->width;$i++) {
    $self->{xlabel}[$i] = '';
  }

  my $t;
  for ($t = $self->duration_end; $t > $self->duration_begin; $t -= 24*60*60) {
    my ($year,$month,$day,$hour,$min,$sec) = Time_to_Date($t);
    my $begin_day = Date_to_Time($year,$month,$day,0,0,0);
    my $label = sprintf("%02d-%02d",$month,$day);
    if ($begin_day >= $self->duration_begin) {
      my $x = $self->_x($begin_day);
      $self->{xlabel}[$x] = $label;
    }
  }
}

sub img() {
  my ($self) = @_;

  return $self->{graph} if defined $self->{graph};

  my $w = $self->{width} + 2 * $self->{border};
  my $h = $self->{height} + 2 * $self->{border};
  my $graph = new GD::Graph::area($w,$h) or die $!;
  $self->{graph} = $graph;

  $graph->set(x_label => 'Day',
	      cumulate => 1,
	      transparent => 0);
	     
  $self->_label_days();

  my (@data);
  push(@data,$self->{xlabel});

  foreach my $measure (sort keys %{$self->{data}}) {
    push(@data,$self->{data}{$measure});
  }
  $graph->set_legend(sort keys %{$self->{data}});
  my $img = $graph->plot(\@data);
  $self->{img} = $img;
  $img;
}

sub png() {
  my ($self) = @_;
  my $img = $self->img();
  return $img->png();
}

1;


=pod

==head1 NAME

ReportLatency::Spectrum - A latency vs time spectrum object

=head1 VERSION

version 0.1

=head1 SYNOPSIS

use LatencyReport::Spectrum

$spectrum = new LatencyReport::Spectrum(
  width => 800,
  height => 200,
  duration => 86400,
  ceiling => 30000
);

$spectrum->add($timestamp,$latency);
$spectrum->add($timestamp,$latency,$count);

print PNG $spectrum->png();

=head1 DESCRIPTION

LatencyReport::Spectrum accepts measurements at specific times and
counts, and when all measurements are collected can be used to render
an image with the full spectrum of responses, with lines representing
the average superimposed on the full spectrum.

=head1 USAGE

=head2 Methods

=head3 Contructors

=over 4
=item * LatencyReport::Spectrum->new(...)

=over 8

=item * width
=item * height

An integer width or height of the final image.  The graph itself will be
2*border pixels narrower.

=item * ceiling

The top pixel of the graph will represent all measurements above this point.
The rest of the pixels will cover ranges between this value and zero.

=item * duration

The x axis of the graph represents duration seconds.  The current time
is the rightmost column of pixels.

=over 4

=item * add(timestamp,value)
=item * add(timestamp,value,count)

Add single or multiple (if count is set) measurements to the latency
graph, at timestamp and value.  If value is greater than ceiling, it
will be truncated to the ceiling value.  If timestamp is outside the
range, it will not be plotted.

=item * png()

Draw a green spectrum, with logarithmic scaling and normalization of
counts to long tails can be seen.  Connect red lines between the
average at each pixel in the graph.  Label the axies.  The PNG is
returned as a scalar.

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
