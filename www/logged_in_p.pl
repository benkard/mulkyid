#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.


use common::sense;
use Modern::Perl;

use JSON;

use File::Slurp;

use CGI;
use CGI::Fast;
use CGI::Session;

do "common.pl";


while (my $cgi = new CGI::Fast) {
  load_config();

  print $cgi->header(-content_type => 'application/json; charset=UTF-8');

  my $cookie = $cgi->cookie('mulkid_session');
  unless ($cookie) {
    say encode_json({logged_in_p => 0});
    exit(0);
  }

  my $session = new CGI::Session("driver:File", $cookie, {Directory=>"/tmp"});
  unless ($session) {
    say encode_json({logged_in_p => 0});
    exit(0);
  }

  my $email        = $cgi->param('email')    or die "No email address supplied";
  my $session_user = $session->param('user');
  if ($session_user ~~ [email_users($email)]) {
    say encode_json({logged_in_p => 1});
  } else {
    say encode_json({logged_in_p => 0});
  }
}

