#! /usr/bin/env perl

use common::sense;
use Modern::Perl;
use JSON;
use Crypt::OpenSSL::RSA;
use File::Slurp;
use File::Path qw(make_path);
use File::Copy;
use LWP::Simple qw(getstore);

sub printspec($$) {
  my ($outfile, $key) = @_;
  my ($n, $e, @stuff) = $key->get_key_parameters;
  say $outfile
      encode_json({"public-key"     => {e => $e->to_decimal, n => $n->to_decimal, algorithm => "RS"},
                   "authentication" => "/browserid/authenticate.html",
                   "provisioning"   => "/browserid/provision.html"});
};

my $configpath = "etc/mulkid";
my $pemfile = "$configpath/rsa2048.pem";

# Download jQuery.
make_path("www/jquery");
if (stat("www/jquery/jquery.js")) {
  say "Using existing copy of jQuery (www/jquery/jquery.js).";
} else {
  say "Fetching jQuery...";
  getstore("http://code.jquery.com/jquery-1.7.2.min.js", "www/jquery/jquery.js")
    or die "Could not fetch jQuery";
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
  open(my $keyfile, ">", $pemfile)
    or die "Cannot open $pemfile for writing: $!";
  print $keyfile $key->get_private_key_string();
  close $keyfile;
  system "chmod 440 $pemfile";
}

# Generate spec file.
open(my $specfile, ">", "browserid.json")
  or die "Cannot open browserid.json for writing: $!";
printspec $specfile, $key;
close($specfile);

say "\n";
say "******************************************************************";
say "* FINISHED.                                                      *";
say "*                                                                *";
say "* Please put browserid.json where it will be served as           *";
say "*     https://<whatever>/.well-known/browserid                   *";
say "* with a content type of                                         *";
say "*     application/json                                           *";
say "* .                                                              *";
say "******************************************************************";
