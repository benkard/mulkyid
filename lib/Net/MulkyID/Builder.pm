#! /usr/bin/env perl

package Net::MulkyID::Builder;

use Module::Build;

our @ISA = 'Module::Build';

sub new {
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);
  return bless $self, $class;
  #my $self = $self->SUPER::new();
  #return $self;
  #return bless {}, shift;
}

sub ACTION_build {
  my ($self, @args) = @_;
  eval "use Net::MulkyID::Setup; setup();";
  if ($@) {
    die $@;
  }
}

1;
