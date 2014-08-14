#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.


use common::sense;
use Modern::Perl;
use syntax 'junction';

use JSON;

use Crypt::OpenSSL::RSA;

use File::Slurp;

use CGI;
use CGI::Fast;

use Time::HiRes qw(time);

do "common.pl";


sub sign($$$$$) {
  # NB.  Treating the jwcrypto code as the spec here.
  my ($key, $client_pubkey, $email, $duration, $domain) = @_;

  my $issued_at = int(1000*time);

  my $cert = {
    iss          => $domain,
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


while (my $cgi = new CGI::Fast) {
  $::MULKONF = {};   # to silence a warning
  load_config();

  my $key = Crypt::OpenSSL::RSA->new_private_key(scalar read_file($::MULKONF->{pemfile}));
  $key->use_pkcs1_padding();
  $key->use_sha256_hash();

  my $cookie = $cgi->cookie('mulkyid_session') or die "No session cookie";
  my $reverse_encrypted_user_session = decode_base64_url($cookie);
  my $plain_user_session = $key->public_decrypt($reverse_encrypted_user_session);
  my ($session_user, $timestamp) = split /#/, $plain_user_session;
  die "User cookie too old" if $timestamp < time - 24*3600;

  print $cgi->header(-content_type => 'application/json; charset=UTF-8');

  my $user_pubkey  = $cgi->param('pubkey')   or die "Nothing to sign";
  my $duration     = $cgi->param('duration') || 24*3600;
  my $email        = $cgi->param('email')    or die "No email address supplied";

  die "User $session_user is not authorized to use this email address ($email)"
    unless any(email_users($email)) eq $session_user;

  my $domain = $::MULKONF->{real_domain};
  my $sig = sign $key, decode_json($user_pubkey), $email, $duration, $domain;
  say encode_json({signature => $sig});
}
