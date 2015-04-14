#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.

use common::sense;
#use Modern::Perl 2011;
use Modern::Perl;

use JSON;

use CGI;
use CGI::Fast;

use OIDC::Lite;
use OIDC::Lite::Client::WebServer;

use Bytes::Random::Secure qw(random_bytes_base64);

do "common.pl";

while (my $cgi = new CGI::Fast) {
  load_config();

  my $fakedomain = $::MULKONF->{fake_domain};
  my $realdomain = $::MULKONF->{real_domain};

  my $claimed_email = $cgi->param('email');
  $claimed_email =~ s/\@$fakedomain/\@$realdomain/ if $fakedomain && $claimed_email;

  given (my $_ = $::MULKONF->{auth_type}) {
    when ('imap') {
      print $cgi->redirect(reluri($cgi, "authenticate-with-password.html?email=$claimed_email"));
    }
    when ('google') {
      my $oidc_client = OIDC::Lite::Client::WebServer->new(
        id => $::MULKONF->{'google_oauth2_client_id'},
        secret => $::MULKONF->{'google_oauth2_client_secret'},
        authorize_uri => 'https://accounts.google.com/o/oauth2/auth',
        access_token_uri => 'https://accounts.google.com/o/oauth2/token'
      );
      my $csrf_token = random_bytes_base64(32);  #256 bits
      my $csrf_token_cookie = make_cookie('mulkyid_csrf_token', $csrf_token);
      print $cgi->redirect(
        -cookie => $csrf_token_cookie,
        -url => $oidc_client->uri_to_redirect(
          redirect_uri => reluri($cgi, 'login.pl'),
          scope => 'openid email',
          state => $csrf_token,
          extra => {
            access_type => 'online',
            login_hint => $claimed_email,
            response_type => 'code'
          })
      );
    }
    default {
      die "Invalid auth_type! " . $::MULKONF->{auth_type};
    }
  }
}
