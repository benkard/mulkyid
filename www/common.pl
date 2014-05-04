#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.

use common::sense;
#use Modern::Perl 2011;
use Modern::Perl;

use Mail::ExpandAliases;
use URI;

sub load_config() {
  $::MULKONF = { };
  do "config.pl";
}

sub email_users($) {
  return @_
    if $::MULKONF->{auth_type} eq 'google';
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

sub reluri($$) {
  my ($cgi, $x) = @_;
  my $uri = URI->new($cgi->url(-full=>1));
  my @path = $uri->path_segments;
  pop @path;
  push @path, $x;
  $uri->path_segments(@path);
  return "$uri";
}
