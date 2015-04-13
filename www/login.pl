#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.

use common::sense;
#use Modern::Perl 2011;
use Modern::Perl;

use JSON;

use File::Slurp;

use Crypt::OpenSSL::RSA;

use CGI;
use CGI::Fast;
use CGI::Cookie;

use Mail::IMAPTalk ;
#use IO::Socket::SSL;

use OIDC::Lite;
use OIDC::Lite::Client::WebServer;
use OIDC::Lite::Model::IDToken;

use LWP::UserAgent;
use HTTP::Request;

do "common.pl";

sub check_imap_password($$) {
  my ($user, $password) = @_;

  #my $socket = IO::Socket::SSL->new('imap.googlemail.com:imaps');
  my $imap = Mail::IMAPTalk->new(
  #  Socket   => $socket,
    Server   => $::MULKONF->{imap_server},
    Port     => $::MULKONF->{imap_port},
    Username => $user,
    Password => $password,
    Uid      => 1
  );
  if ($imap) {
    $imap->logout;
    return 1;
  } else {
    return 0;
  }
}

sub cookie_for_user {
  my ($user) = @_;

  my $key = Crypt::OpenSSL::RSA->new_private_key(scalar read_file($::MULKONF->{pemfile}));
  $key->use_pkcs1_padding();
  $key->use_sha256_hash();

  my $plain_user_session = $user . '#' . time;
  my $reverse_encrypted_user_session = $key->private_encrypt($plain_user_session);
  my $cookie = CGI::Cookie->new(-name => 'mulkyid_session', -value =>encode_base64_url($reverse_encrypted_user_session));
}

while (my $cgi = new CGI::Fast) {
  load_config();

  given (my $_ = $::MULKONF->{auth_type}) {
    when ('imap') {
      my $email = $cgi->param('email') or die "No email address provided";
      my $password = $cgi->param('password') or die "Empty password";
      for my $user (email_users($email)) {
        #say STDERR "Trying user: $user";
        if (check_imap_password($user, $password)) {
          print $cgi->header(-content_type => 'application/json; charset=UTF-8');
          print $cgi->header(-cookie=>cookie_for_user($user));
          say encode_json({user => $user});
          exit 0;
        }
      }
      die "Could not authenticate.";
    }
    when ('google') {
      my $code = $cgi->param('code') or die "Authorization code is missing.";
      my $oidc_client = OIDC::Lite::Client::WebServer->new(
        id => $::MULKONF->{'google_oauth2_client_id'},
        secret => $::MULKONF->{'google_oauth2_client_secret'},
        authorize_uri => 'https://accounts.google.com/o/oauth2/auth',
        access_token_uri => 'https://accounts.google.com/o/oauth2/token'
      );

      # Acquire access token.
      my $token = $oidc_client->get_access_token(
        code => $code,
        redirect_uri => reluri($cgi, 'login.pl')
      );
      unless ($token) {
        my $oidc_response = $oidc_client->last_response;
        die "Could not acquire access token: " . $oidc_response->code . " (" . $oidc_response->content . ")";
      }

      # Extract ID token.
      my $id_token = OIDC::Lite::Model::IDToken->load($token->id_token);

      # Acquire user information.
      my $userinfo_request =  HTTP::Request->new(GET => 'https://www.googleapis.com/oauth2/v3/userinfo');
      $userinfo_request->header(Authorization => "Bearer " . $token->access_token);
      my $userinfo_response = LWP::UserAgent->new->request($userinfo_request);
      unless ($userinfo_response->is_success) {
        die "Could not acquire user information: " . $userinfo_response->code . " (" . $userinfo_response->content . ")";
      }
      my $userinfo = decode_json($userinfo_response->content);

      # Verify e-mail and sign user's identity assertion.
      unless ($userinfo->{'email_verified'}) {
        die "User email is not verified."
      }
      my $verified_email = $userinfo->{'email'};
      my $fakedomain = $::MULKONF->{'fake_domain'};
      my $realdomain = $::MULKONF->{'real_domain'};
      $verified_email =~ s/\@$realdomain/\@$fakedomain/ if $fakedomain;
      print $cgi->redirect(-cookie => cookie_for_user($verified_email), -url => reluri($cgi, 'successful-login.html'));
    }
    default {
      die "Invalid auth_type.  Check MulkyID configuration!";
    }
  }
}
