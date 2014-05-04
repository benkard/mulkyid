#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.

use common::sense;
#use Modern::Perl 2011;
use Modern::Perl;

use JSON;

use CGI;
use CGI::Fast;
use CGI::Session;

use Mail::IMAPTalk ;
use Net::Google::FederatedLogin;
#use IO::Socket::SSL;

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


while (my $cgi = new CGI::Fast) {
  load_config;

  my $cookie = $cgi->cookie('mulkid_session');
  my $session;
  if ($cookie) {
    $session = new CGI::Session("driver:File", $cookie, {Directory=>"/tmp"});
    print $cgi->header(-content_type => 'application/json; charset=UTF-8');
  } else {
    $session = new CGI::Session("driver:File", undef, {Directory=>"/tmp"});
    my $cookie = $cgi->cookie(-name     => 'mulkid_session',
                              -value    => $session->id,
                              -expires  => '+1d',
                              -secure   => 1,
                              -httponly => 1,
                              #-domain   => '.mulk.eu'
                             );
    print $cgi->header(-content_type => 'application/json; charset=UTF-8',
                       -cookie       => $cookie);
  }

  my $email = $cgi->param('email') or die "No email address provided";

  for ($::MULKONF->{auth_type}) {
    when ('imap') {
      my $password = $cgi->param('password') or die "Empty password";
      for my $user (email_users($email)) {
        #say STDERR "Trying user: $user";
        if (check_imap_password($user, $password)) {
          $session->param('user', $user);
          #say encode_json({user => $user});
          print $cgi->redirect(-url => reluri($cgi, 'successful-login.html'));
          exit 0;
        }
      }
    }
    when ('google') {
      my $g = Net::Google::FederatedLogin->new(
        cgi => $cgi,
        return_to => $cgi->url()
      );
      $g->verify_auth or die "Could not verify the OpenID assertion!";
      my $ext = $g->get_extension('http://openid.net/srv/ax/1.0');
      my $verified_email = $ext->get_parameter('value.email');
      $session->param('user', $verified_email);
      #say encode_json({user => $user});
      print $cgi->redirect(-url => reluri($cgi, 'successful-login.html'));
      exit 0;
    }
    default {
      die "Invalid auth_type.  Check MulkyID configuration!";
    }
  }

  die "Could not authenticate.";
}
