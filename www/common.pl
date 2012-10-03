#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.

use common::sense;
#use Modern::Perl 2011;
use Modern::Perl;

use Mail::ExpandAliases;

sub load_config() {
  $::MULKONF = { };
  do "config.pl";
}

sub email_users($) {
  my ($email) = @_;
  my $alias;
  if ($email =~ /^(.*?)@/) { $alias = $1; }
  my $aliases_file = $::MULKONF->{aliases};
  if (not ($aliases_file eq ".")) {
    my $aliases = Mail::ExpandAliases->new($aliases_file);
    my $email_users = $aliases->expand($alias) or die "User not found";
    return @$email_users;
  } else {
    return ($alias);
  }
}
