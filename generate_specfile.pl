#! /usr/bin/env perl
# Copyright 2012, Matthias Andreas Benkard <code@mail.matthias.benkard.de>.

use common::sense;
use Modern::Perl;
use JSON;
use Crypt::OpenSSL::RSA;
use File::Slurp;

my $key = Crypt::OpenSSL::RSA->new_private_key(scalar read_file('/etc/mulkid/rsa2048.pem'));
my ($n, $e, @stuff) = $key->get_key_parameters;
say encode_json({"public-key"     => {e => $e->to_decimal, n => $n->to_decimal, algorithm => "RS"},
                 "authentication" => "/browserid/authenticate.html",
                 "provisioning"   => "/browserid/provision.html"});
