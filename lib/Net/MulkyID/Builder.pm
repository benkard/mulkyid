#! /usr/bin/env perl

package Net::MulkyID::Builder;

use Module::Build;

our @ISA = 'Module::Build';

sub new {
  my ($class, @args) = @_;
  my $self = $class->SUPER::new(@args);
  return bless $self, $class;
}

sub ACTION_configure {
  my ($self, @args) = @_;
  eval "use Net::MulkyID::Setup; configure();";
  if ($@) {
    die $@;
  }
}

sub ACTION_build {
  my ($self, @args) = @_;
  eval "use Net::MulkyID::Setup; build();";
  if ($@) {
    die $@;
  }
}

1;
