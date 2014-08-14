#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.

use common::sense;
#use Modern::Perl 2011;
use Modern::Perl;

use Mail::ExpandAliases;
use URI;
use MIME::Base64 qw(encode_base64 decode_base64);

sub load_config() {
  $::MULKONF = { };
  do "config.pl";
}

sub email_users($) {
  my ($email) = @_;
  my $fakedomain = $::MULKONF->{fake_domain};
  my $realdomain = $::MULKONF->{real_domain};
  $email =~ s/\@$realdomain/\@$fakedomain/ if $fakedomain;
  return ($email)
    if $::MULKONF->{auth_type} eq 'google';
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

sub decode_base64_url($) {
  # From: https://github.com/ptarjan/base64url/blob/master/perl.pl
  (my $s = shift) =~ tr{-_}{+/};
  $s .= '=' x (4 - length($s));
  return decode_base64($s);
}

sub encode_base64_url($) {
  my ($s) = shift;
  $s = encode_base64($s);
  $s =~ tr{+/}{-_};
  $s =~ s/=*$//;
  $s =~ s/\n//g;
  return $s;
}
