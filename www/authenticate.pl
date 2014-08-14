#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.

use common::sense;
#use Modern::Perl 2011;
use Modern::Perl;

use JSON;

use CGI;
use CGI::Fast;

use Net::Google::FederatedLogin;

do "common.pl";

while (my $cgi = new CGI::Fast) {
  load_config();

  my $fakedomain = $::MULKONF->{fake_domain};
  my $realdomain = $::MULKONF->{real_domain};

  my $claimed_email = $cgi->param('email');
  $claimed_email =~ s/\@$fakedomain/\@$realdomain/ if $fakedomain;

  given (my $_ = $::MULKONF->{auth_type}) {
    when ('imap') {
      print $cgi->redirect(reluri($cgi, "authenticate-with-password.html?email=$claimed_email"));
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
      print $cgi->redirect($g->get_auth_url());
    }
    default {
      die "Invalid auth_type! " . $::MULKONF->{auth_type};
    }
  }
}
