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

package ReportLatency::Spectrum;

use strict;
use Math::Round;
use Date::Calc qw(Time_to_Date Date_to_Time);
use GD;
use vars qw($VERSION);

$VERSION     = 0.1;

sub new {
  my $class = shift;
  my %p = @_;

  $p{width} = 1000 unless exists $p{width};
  $p{height} = 250 unless exists $p{height};
  $p{duration} = 14 * 24 * 3600 unless exists $p{duration};
  $p{ceiling} = 30000 unless exists $p{ceiling};
  $p{floor} = 300 unless exists $p{floor};
  $p{logarithmic} = 1 unless exists $p{logarithmic};
  $p{border} = 0 unless exists $p{border};

  my $self  = bless {}, $class;

  foreach my $param (qw( width height border ceiling floor duration
			 logarithmic)) {
    $self->{$param} = $p{$param};
  }
  $self->{maxval} = 0;

  $self->{data} = [];
  foreach my $i (0..$p{width}-1) {
    $self->{data}[$i] = [];
  }

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

sub ceiling {
  my ($self) = @_;
  return $self->{ceiling};
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

sub _y {
  my ($self,$measure) = @_;
  return undef if ($measure < 0);

  my $floor = $self->{floor};
  my $ceiling = $self->{ceiling};
  my $height = $self->{height};

  my $y;
  if ($self->{logarithmic}) {
    if ($measure <= $floor) {
      $y = 0;
    } else {
      $y = int((log($measure)-log($floor))/(log($ceiling)-log($floor))
	       * $height);
    }
  } else {
    $y = round($measure * $height / $ceiling);
  }
  if ($y > $height-1) {
    $y = $height-1;
  }
  return $y;
}

sub add {
  my ($self,$timestamp,$measure,$count) = @_;
  $count=1 unless defined $count;
  my $x = $self->_x($timestamp);
  if (defined $x) {
    my $y = $self->_y($measure);
    if (defined $y) {
      $self->{data}[$x][$y] += $count;
      if ($self->{data}[$x][$y] > $self->{maxval}) {
	$self->{maxval} = $self->{data}[$x][$y];
      }
      return $self->{data}[$x][$y];
    }
  }
  undef;
}

sub add_row {
  my ($self,$row) = @_;
  my $points=0;

  my $timestamp = $row->{'timestamp'};
  my $total = $row->{'total'};
  my $count = $row->{'count'};
  if (defined $total && defined $count) {
    my $high = $row->{'high'};
    if (defined $high && $high ne '' && $count>1) {
      $self->add($timestamp, $high);
      $total -= $high;
      $count--;
      $points++;
    }
    
    my $low = $row->{'low'};
    if (defined $low && $low ne '' && $count>1) {
      $self->add($timestamp, $low);
      $total -= $low;
      $count--;
      $points++;
    }

    if ($count>0) {
      $self->add($timestamp, $total/$count, $count);
      $points++;
    }
  }
  $points;
}

sub _text_color {
  my ($self) = @_;
  return $self->{text_color} if defined $self->{text_color};
  my $img = $self->img;
  $self->{text_color} = $img->colorResolve(0,191,0);
  return $self->{text_color};
}

sub _plot_xtic {
  my ($self,$t,$label) = @_;
  my $color = $self->_text_color;
  my $border = $self->{border};
  my $height = $self->{height};
  my $width = $self->{width};
  my $img = $self->img;
  my $x = $self->_x($t) + $border;
  $img->line($x,$border+$height+1, $x,
	     $border+$height+4,$color);
  if ($label) {
    $img->string(gdSmallFont,$x-14,int($height+5*$border/4),
		 $label,$color);
  }
}

sub _plot_ytic {
  my ($self,$latency,$label) = @_;
  my $color = $self->_text_color;
  my $border = $self->{border};
  my $height = $self->{height};
  my $width = $self->{width};
  my $img = $self->img;
  my $y = $height - $self->_y($latency) + $border;
  if ($label) {
    $img->line($border-7, $y, $border-1, $y, $color);
    $img->stringUp(gdSmallFont,int($border/8),
		   $y+8,
		   $label,$color);
  } else {
    $img->line($border-3, $y, $border-1, $y, $color);
  }
}

sub _draw_axes {
  my ($self) = @_;
  my $color = $self->_text_color;
  my $border = $self->{border};
  my $height = $self->{height};
  my $width = $self->{width};
  my $img = $self->img;
  $img->line($border-1,
	     $border+$height+1,
	     $border+$width,
	     $border+$height+1,
	     $color);
  $img->line($border-1,
	     $border+$height+1,
	     $border-1,
	     $border,
	     $color);
}

sub _label_days {
  my ($self) = @_;

  my $border = $self->{border};
  return unless $border>4;

  my $t;
  my @ticks;
  for ($t = $self->duration_end; $t > $self->duration_begin; $t -= 24*60*60) {
    my ($year,$month,$day,$hour,$min,$sec) = Time_to_Date($t);
    my $begin_day = Date_to_Time($year,$month,$day,0,0,0);
    my $label = sprintf("%02d-%02d",$month,$day);
    if ($t > $self->duration_begin) {
      $self->_plot_xtic($begin_day,$label);
    }
  }
}

sub _label_y_axis_linear {
  my ($self) = @_;

  my $color = $self->_text_color;
  my $border = $self->{border};
  my $img = $self->img;
  my $ceiling = $self->{ceiling};
  my $floor = $self->{floor};

  if ($self->{logarithmic}) {
    my ($log_floor) = int(log($floor)/log(10));
    my ($log_ceil) = int(log($ceiling)/log(10));
    for (my $l_power=$log_floor;$l_power<=$log_ceil;$l_power++) {
      my $label_value = 10 ** $l_power;
      if ($label_value >= $floor) {
	my $label;
	if ($label_value>=1000) {
	  $label = ($label_value/1000) . 's';
	} else {
	  $label = $label_value . "ms";
	}
	$self->_plot_ytic($label_value,$label);
      }
      for (my $mult=2;$mult<10;$mult++) {
	my $value = $label_value * $mult;
	if ($value >= $floor && $value <= $ceiling) {
	  $self->_plot_ytic($value);
	}
      }
    }
  } else {
    # better heuristics needed..
    my $step=1000;
    while ($self->{height}/$step>20) {
      $step *=10;
    }

    for (my $y=$step;$y<$ceiling;$y+=$step) {
      my $label;
      if ($y % ($step*10) == 0) {
	$label = $y . " ms";
      }
      $self->_plot_ytic($y,$label);
    }
  }
}

sub _label_image {
  my ($self) = @_;

  my $duration = $self->duration;
  if ($duration < 62*86400 && $duration > 2*86400) {
    $self->_label_days();
  }

  $self->_draw_axes;

  $self->_label_y_axis_linear;
}

sub img() {
  my ($self) = @_;

  return $self->{img} if defined $self->{img};

  my $w = $self->{width} + 2 * $self->{border};
  my $h = $self->{height} + 2 * $self->{border};
  my $img = new GD::Image->newTrueColor($w,$h) or die $!;
  $self->{img} = $img;

  my @color;
  for (my $i=0;$i<128;$i++) {
    $color[$i] = $img->colorResolve(0,128+$i,0);
  }
  for (my $i=128;$i<256;$i++) {
    $color[$i] = $img->colorResolve($i-128,255,$i-128);
  }

  my $avg_color = $img->colorResolve(128,0,0);

  my ($last_x,$last_y);

  for (my $x=0;$x<$self->{width};$x++) {
    my $total=0;
    my $samples=0;
    for (my $y=0;$y<$self->{height};$y++) {
      if (defined $self->{data}[$x][$y]) {
	$total += $y * $self->{data}[$x][$y];
	$samples += $self->{data}[$x][$y];
	my $val = int(254*$self->{data}[$x][$y]/$self->{maxval})+1;
	$img->setPixel($x+$self->{border},
		       $self->{height}-$y-1+$self->{border},
		       $color[$val]);
      }
    }
    if ($samples>0) {
      my $avg = $total/$samples;
      if (defined $last_x && defined $last_y) {
	if (0) {
	  $img->setPixel($x+$self->{border},
			 $self->{height}-$avg-1+$self->{border},
			 $avg_color);
	} else {
	  $img->line($last_x+$self->{border},
		     $self->{height}-$last_y-1+$self->{border},
		     $x+$self->{border},
		     $self->{height}-$avg-1+$self->{border},
		     $avg_color);
	}
      }
      $last_x = $x;
      $last_y = $avg;
    }
  }

  $self->_label_image();
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
