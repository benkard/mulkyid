#! /usr/bin/env perl
# Copyright 2012, 2014, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.

package Net::MulkyID::Setup;

use common::sense;
use Modern::Perl;
use JSON;
use Crypt::OpenSSL::RSA;
use File::Slurp qw(write_file read_file);
use File::Path qw(make_path);
use File::Copy;
use LWP::Simple qw(getstore);
use Data::Dumper;
#use autodie;

use base 'Exporter';
our @EXPORT = qw(setup);

sub prompt($$) {
  my ($question, $default) = @_;
  $|++;
  print "${question} \[${default}\] ";
  $_ = <>;
  chomp;
  if ($_) {
    return $_;
  } else {
    return $default;
  }
}

sub makespec($$) {
  my ($key, $basepath) = @_;
  my ($n, $e, @stuff) = $key->get_key_parameters;
  return
    encode_json({"public-key"     => {e => $e->to_decimal, n => $n->to_decimal, algorithm => "RS"},
                 "authentication" => "$basepath/authenticate.html",
                 "provisioning"   => "$basepath/provision.html"});
};

sub setup() {
  my $conffile = "www/config.pl";

  # Generate configuration file.
  $::MULKONF = { };
  if (stat($conffile)) {
    say "Found existing configuration ($conffile).";
    do $conffile;
  }

  my $configpath   = $::MULKONF->{configpath}   // "/etc/mulkyid";
  my $pemfile      = $::MULKONF->{pemfile}      // "$configpath/rsa2048.pem";
  my $auth_type    = $::MULKONF->{auth_type}    // "imap";
  my $aliases_file = $::MULKONF->{aliases_file} // "/etc/aliases";
  my $imap_server  = $::MULKONF->{imap_server}  // "localhost";
  my $imap_port    = $::MULKONF->{imap_port}    // 143;
  my $basepath     = $::MULKONF->{basepath}     // "/browserid";
  my $fake_domain  = $::MULKONF->{fake_domain}  // "";
  my $real_domain  = $::MULKONF->{real_domain}  // "";
  my $google_oauth2_client_secret = $::MULKONF->{google_oauth2_client_secret}  // "";
  my $google_oauth2_client_id     = $::MULKONF->{google_oauth2_client_id}      // "";
  $configpath = prompt("Where shall I put configuration files?", $configpath);
  $pemfile    = prompt("Where shall I put the private key?", $pemfile);
  $auth_type  = prompt("How will users authenticate? (imap, google)", $auth_type);
  $basepath   = prompt("What will be the web-facing base path for IdP files and scripts?", $basepath);
  given (my $_ = $auth_type) {
    when ("imap") {
      $aliases_file = prompt("Where is the aliases file?  Type a single dot for none.", $aliases_file);
      $imap_server  = prompt("What is the IMAP server's address?", $imap_server);
      $imap_port    = int(prompt("What is the IMAP server's port?", $imap_port));
    }
    when ("google") {
      $fake_domain = prompt("Fake domain name for email addresses?  Type a single dot for none. (FOR DEVELOPMENT)", $fake_domain);
      if ($fake_domain eq '.' or $fake_domain eq '') {
        $fake_domain = '';
      } else {
        $real_domain = prompt("Real domain name?", $real_domain);
        $real_domain = '' if ($real_domain eq '.');
      }
      $google_oauth2_client_id = prompt("Google OAuth2 client ID?", $google_oauth2_client_id);
      $google_oauth2_client_secret = prompt("Google OAuth2 client secret?", $google_oauth2_client_secret);
    }
    default {
      die "Invalid authentication type";
    }
  }

  say "OK.";

  # Download jQuery.
  make_path("www/jquery");
  if (stat("www/jquery/jquery.js")) {
    say "Using existing copy of jQuery (www/jquery/jquery.js).";
  } else {
    say "Fetching jQuery...";
    getstore("http://code.jquery.com/jquery-1.7.2.min.js", "www/jquery/jquery.js")
      or die "Could not fetch jQuery";
    say "jQuery saved to: www/jquery/jquery.js";
  }

  # Generate the private key.
  my $key;
  if (stat($pemfile)) {
    say "Using existing private key ($pemfile).";
    $key = Crypt::OpenSSL::RSA->new_private_key(scalar read_file($pemfile));
  } else {
    say "Generating private key...";
    $key = Crypt::OpenSSL::RSA->generate_key(2048);
    make_path($configpath);
    write_file($pemfile, $key->get_private_key_string())
      or die "Could not write private key to $pemfile: $!";
    say "Private key saved to: $pemfile";
    chmod 0440, $pemfile;
  }

  # Generate spec file.
  write_file("browserid.json", makespec($key, $basepath))
    or die "Could not write spec to browserid.json: $!";
  say "Persona spec file saved to: browserid.json";

  # Generate configuration file.
  $::MULKONF = {
    configpath   => $configpath,
    pemfile      => $pemfile,
    aliases_file => $aliases_file,
    imap_server  => $imap_server,
    imap_port    => $imap_port,
    basepath     => $basepath,
    auth_type    => $auth_type,
    fake_domain  => $fake_domain,
    real_domain  => $real_domain,
    google_oauth2_client_secret => $google_oauth2_client_secret,
    google_oauth2_client_id     => $google_oauth2_client_id
  };
  write_file($conffile, <<EOF
#! /usr/bin/env perl
# NB. Do not edit this file directly.  It is overwritten with each run of setup.pl.
@{[Data::Dumper->Dump([$::MULKONF], ["::MULKONF"])]}
1;
EOF
  ) or die "Could not write configuration to $conffile: $!";
  say "Configuration saved to: $conffile";

  say "";
  say "******************************************************************";
  say "* FINISHED.                                                      *";
  say "*                                                                *";
  say "* Please put browserid.json where it will be served as           *";
  say "*     https://<whatever>/.well-known/browserid                   *";
  say "* with a content type of:                                        *";
  say "*     application/json                                           *";
  say "*                                                                *";
  say "* In addition, please ensure that the private key file can be    *";
  say "* read by the web server by assigning the file to the            *";
  say "* appropriate owner.                                             *";
  say "******************************************************************";
}

1;

