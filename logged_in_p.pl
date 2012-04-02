#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.


use common::sense;
use Modern::Perl;

use JSON;

use File::Slurp;

use CGI;
use CGI::Fast;
use CGI::Session;

use Mail::ExpandAliases;


while (my $cgi = new CGI::Fast) {
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

  my $aliases = Mail::ExpandAliases->new("/etc/aliases");
  my $email        = $cgi->param('email')    or die "No email address supplied";
  my $session_user = $session->param('user');

  my $alias;
  if ($email =~ /^(.*?)@/) { $alias = $1; }
  my $email_users = $aliases->expand($alias) or die "User not found";

  if ($session_user ~~ @$email_users) {
    say encode_json({logged_in_p => 1});
  } else {
    say encode_json({logged_in_p => 0});
  }
}

