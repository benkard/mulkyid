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
#use IO::Socket::SSL;

do "common.pl";

sub check_password($$$) {
  my ($config, $user, $password) = @_;

  #my $socket = IO::Socket::SSL->new('imap.googlemail.com:imaps');
  my $imap = Mail::IMAPTalk->new(
  #  Socket   => $socket,
    Server   => $config->{imap_server},
    Port     => $config->{imap_port},
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
  local $::MULKONF = { };
  do "config.pl";

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

  my $email    = $cgi->param('email')    or die "No email address provided";
  my $password = $cgi->param('password') or die "Empty password";

  for my $user (email_users($::MULKONF, $email)) {
    #say STDERR "Trying user: $user";
    if (check_password($::MULKONF, $user, $password)) {
      $session->param('user', $user);
      say encode_json({user => $user});
      exit 0;
    }
  }

  die "Could not authenticate with mail server.";
}
