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
  load_config();

  my $cookie = $cgi->cookie('mulkid_session');
  my $session = new CGI::Session("driver:File", $cookie, {Directory=>"/tmp"});
  given (my $_ = $::MULKONF->{auth_type}) {
    when ('imap') {
      my $email = $cgi->param('email') or die "No email address provided";
      my $password = $cgi->param('password') or die "Empty password";
      for my $user (email_users($email)) {
        #say STDERR "Trying user: $user";
        if (check_imap_password($user, $password)) {
          $session->param('user', $user);
          print $cgi->header(-content_type => 'application/json; charset=UTF-8');
          say encode_json({user => $user});
          exit 0;
        }
      }
      die "Could not authenticate.";
    }
    when ('google') {
      my $g = Net::Google::FederatedLogin->new(
        cgi => $cgi,
        return_to => $cgi->url()
      );
      $g->verify_auth or die "Could not verify the OpenID assertion!";
      my $ext = $g->get_extension('http://openid.net/srv/ax/1.0');
      my $verified_email = $ext->get_parameter('value.email');
      my $fakedomain = $::MULKONF->{fake_domain};
      my $realdomain = $::MULKONF->{real_domain};
      $verified_email =~ s/\@$realdomain/\@$fakedomain/ if $fakedomain;
      $session->param('user', $verified_email);
      print $cgi->redirect(-url => reluri($cgi, 'successful-login.html'));
      exit 0;
    }
    default {
      die "Invalid auth_type.  Check MulkyID configuration!";
    }
  }
}
