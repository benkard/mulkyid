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

while (my $cgi = new CGI::Fast) {
  load_config();

  my $claimed_email = $cgi->param('email');

  my $g = Net::Google::FederatedLogin->new(
    claimed_id => $claimed_email,
    return_to  => reluri($cgi, 'login.pl'),
    extensions => [{ns          => 'ax',
                    uri         => 'http://openid.net/srv/ax/1.0',
                    attributes  => {mode        => 'fetch_request',
                                    required    => 'email',
                                    type        => {email => 'http://axschema.org/contact/email'}}}]
  );

  my $cookie = $cgi->cookie('mulkid_session');
  my $session = new CGI::Session("driver:File", $cookie, {Directory=>"/tmp"});
  $session->param('claimed_email', $claimed_email);
  if ($cookie) {
    print $cgi->redirect(-url => $g->get_auth_url());
  } else {
    my $cookie = $cgi->cookie(-name     => 'mulkid_session',
                              -value    => $session->id,
                              -expires  => '+1d',
                              #-secure   => 1,
                              -httponly => 1,
                              #-domain   => '.'.$::MULKONF->{realm}
                             );
    print $cgi->redirect(-cookie => $cookie, -url => $g->get_auth_url());
  }
}
