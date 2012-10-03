#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.


use common::sense;
use Modern::Perl;

use JSON;

use Crypt::OpenSSL::RSA;

use File::Slurp;

use CGI;
use CGI::Fast;
use CGI::Session;

use Mail::ExpandAliases;

use MIME::Base64 qw(encode_base64 decode_base64);

use Time::HiRes qw(time);


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


sub sign($$$$) {
  # NB.  Treating the jwcrypto code as the spec here.
  my ($key, $client_pubkey, $email, $duration) = @_;

  my $issued_at = int(1000*time);

  my $cert = {
    iss          => "mulk.eu",
    exp          => $issued_at + 1000*$duration,
    iat          => $issued_at,
    "public-key" => $client_pubkey,
    principal    => { email => $email }
  };

  my $header = {typ => "JWT", alg => "RS256"};
  my $header_bytes = encode_base64_url(encode_json($header));
  my $cert_bytes   = encode_base64_url(encode_json($cert));
  my $string_to_sign = $header_bytes . "." . $cert_bytes;

  my $sig = $key->sign($string_to_sign);
  my $sig_bytes = encode_base64_url($sig);

  return $header_bytes . "." . $cert_bytes . "." . $sig_bytes;
}


our $MULKONF;
do "config.pl";

while (my $cgi = new CGI::Fast) {
  my $cookie = $cgi->cookie('mulkid_session') or die "No session cookie";
  my $session = new CGI::Session("driver:File", $cookie, {Directory=>"/tmp"}) or die "Invalid session cookie";
  print $cgi->header(-content_type => 'application/json; charset=UTF-8');

  my $key = Crypt::OpenSSL::RSA->new_private_key(scalar read_file($MULKONF->{pemfile}));
  $key->use_pkcs1_padding();
  $key->use_sha256_hash();

  my $aliases = Mail::ExpandAliases->new("/etc/aliases");
  my $user_pubkey  = $cgi->param('pubkey')   or die "Nothing to sign";
  my $duration     = $cgi->param('duration') || 24*3600;
  my $email        = $cgi->param('email')    or die "No email address supplied";
  my $session_user = $session->param('user');

  my $alias;
  my $domain;
  if ($email =~ /^(.*?)@(.*)/) { $alias = $1; $domain = $2; }
  my $email_users = $aliases->expand($alias) or die "User not found";

  die "User is not authorized to use this email address"
    unless ($session_user ~~ @$email_users);

  my $sig = sign $key, decode_json($user_pubkey), $email, $duration, $domain;
  say encode_json({signature => $sig});
}
