#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.

use common::sense;
#use Modern::Perl 2011;
use Modern::Perl;

use JSON;

use CGI;
use CGI::Fast;
use CGI::Session;

use Net::Google::FederatedLogin;

do "common.pl";

sub redirect_with_cookie($$$$) {
  my ($cgi, $uri, $session, $cookie) = @_;
  if ($cookie) {
    print $cgi->redirect(-url => $uri);
  } else {
    my $cookie = $cgi->cookie(-name     => 'mulkid_session',
                              -value    => $session->id,
                              -expires  => '+1d',
                              -secure   => 1,
                              -httponly => 1,
                              #-domain   => '.'.$::MULKONF->{realm}
                             );
    print $cgi->redirect(-cookie => $cookie, -url => $uri);
  }
}

while (my $cgi = new CGI::Fast) {
  load_config();

  my $claimed_email = $cgi->param('email');
  my $cookie = $cgi->cookie('mulkid_session');
  my $session = new CGI::Session("driver:File", $cookie, {Directory=>"/tmp"});

  my $fakedomain = $::MULKONF->{fake_domain};
  my $realdomain = $::MULKONF->{real_domain};
  $claimed_email =~ s/\@$fakedomain/\@$realdomain/ if $fakedomain;

  $session->param('claimed_email', $claimed_email);

  given (my $_ = $::MULKONF->{auth_type}) {
    when ('imap') {
      redirect_with_cookie($cgi, reluri($cgi, "authenticate-with-password.html?email=$claimed_email"), $session, $cookie);
    }
    when ('google') {
      my $g = Net::Google::FederatedLogin->new(
        claimed_id => $claimed_email,
        return_to  => reluri($cgi, 'login.pl'),
        extensions => [{ns          => 'ax',
                        uri         => 'http://openid.net/srv/ax/1.0',
                        attributes  => {mode        => 'fetch_request',
                                        required    => 'email',
                                        type        => {email => 'http://axschema.org/contact/email'}}}]
      );
      redirect_with_cookie($cgi, $g->get_auth_url(), $session, $cookie);
    }
    default {
      die "Invalid auth_type! " . $::MULKONF->{auth_type};
    }
  }
}
