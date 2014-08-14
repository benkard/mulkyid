#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.


use common::sense;
use Modern::Perl;
use syntax 'junction';

use JSON;

use File::Slurp;

use Crypt::OpenSSL::RSA;

use CGI;
use CGI::Fast;
use CGI::Session;

do "common.pl";


while (my $cgi = new CGI::Fast) {
  $::MULKONF = {};   # to silence a warning
  load_config();

  print $cgi->header(-content_type => 'application/json; charset=UTF-8');

  my $cookie = $cgi->cookie('mulkyid_session');

  unless ($cookie) {
    say encode_json({logged_in_p => 0});
    exit(0);
  }

  my $key = Crypt::OpenSSL::RSA->new_private_key(scalar read_file($::MULKONF->{pemfile}));
  $key->use_pkcs1_padding();
  $key->use_sha256_hash();

  my $reverse_encrypted_user_session = decode_base64_url($cookie);
  my $plain_user_session = $key->public_decrypt($reverse_encrypted_user_session);
  my ($session_user, $timestamp) = split /#/, $plain_user_session;

  if ($timestamp < time - 24*3600) {
    say encode_json({logged_in_p => 0});
    exit(0);
  }

  my $email = $cgi->param('email')    or die "No email address supplied";
  if (any(email_users($email)) eq $session_user) {
    say encode_json({logged_in_p => 1});
  } else {
    say encode_json({logged_in_p => 0});
  }
}

