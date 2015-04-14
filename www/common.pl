#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.

use common::sense;
#use Modern::Perl 2011;
use Modern::Perl;

use File::Slurp;
use Mail::ExpandAliases;
use URI;
use MIME::Base64 qw(encode_base64 decode_base64);
use Crypt::OpenSSL::RSA;
use CGI::Cookie;

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
  my $uri = "https://" . $::MULKONF->{real_domain} . $::MULKONF->{basepath} . "/$x";
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

sub acquire_private_key() {
  my $key = Crypt::OpenSSL::RSA->new_private_key(scalar read_file($::MULKONF->{pemfile}));
  $key->use_pkcs1_padding();
  $key->use_sha256_hash();
  return $key;
}

sub make_cookie($$) {
  my ($name, $value) = @_;
  my $key = acquire_private_key;
  my $reverse_encrypted_value = $key->private_encrypt($value);
  my $cookie = CGI::Cookie->new(-name => $name, -value =>encode_base64_url($reverse_encrypted_value));
}

sub read_cookie($$) {
  my ($cgi, $name) = @_;
  my $cookie = $cgi->cookie($name);
  return unless ($cookie);
  my $key = acquire_private_key;
  my $value = $key->public_decrypt(decode_base64_url($cookie));
  warn "cookie `$name` was forged!" unless $value;
  return $value;
}
