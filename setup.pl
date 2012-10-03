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
  my ($outfile, $pemfile) = @_;
  my $key = Crypt::OpenSSL::RSA->new_private_key(scalar read_file($pemfile));
  my ($n, $e, @stuff) = $key->get_key_parameters;
  say $outfile
      encode_json({"public-key"     => {e => $e->to_decimal, n => $n->to_decimal, algorithm => "RS"},
                   "authentication" => "/browserid/authenticate.html",
                   "provisioning"   => "/browserid/provision.html"});
};

my $wwwuser = "www";
my $configpath = "etc/mulkid";

# Download jQuery.
make_path("www/jquery");
say "Fetching jQuery...";
getstore("http://code.jquery.com/jquery-1.7.2.min.js", "www/jquery/jquery.js");

# Generate the private key.
say "Generating private key...";
#FIXME: Don't do this if the private key already exists!
system "openssl genpkey -algorithm rsa -out rsa2048.pem -pkeyopt rsa_keygen_bits:2048";

# Install the private key.
make_path($configpath);
my $pemfile = "$configpath/rsa2048.pem";
move("rsa2048.pem", $pemfile) or die "Could not move rsa2048.pem to $configpath";
system "chmod go=      $pemfile";
system "chown $wwwuser $pemfile";

# Generate spec file.
open(my $out, ">", "browserid.json")
  or die "Cannot open browserid.json for writing: $!";
printspec $out, $pemfile;
close($out);

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
