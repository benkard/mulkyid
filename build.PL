#! /usr/bin/env perl

use lib q(./lib);
use Net::MulkyID::Builder;  # Or whatever you want to call it

my $build = Net::MulkyID::Builder->new
  (
   module_name        => 'Net::MulkyID',
   #license            => 'agpl_3',
   dist_author        => 'Matthias Andreas Benkard <code@mulk.eu>',
   dist_abstract      => 'A simple Persona IdP.',
   requires           => {
                          "Carp" => 0,
                          "CGI" => 0,
                          "CGI::Fast" => 0,
                          "CGI::Session" => 0,
                          "common::sense" => 0,
                          "Crypt::OpenSSL::RSA" => 0,
                          "File::Slurp" => 0,
                          "JSON" => 0,
                          "MIME::Base64" => 0,
                          "Mail::ExpandAliases" => 0,
                          "Mail::IMAPTalk" => 0,
                          "Modern::Perl" => 0,
                          "Time::HiRes" => 0,
                         },
   build_requires     => {
                          "LWP::Simple" => 0,
                          "Modern::Perl" => 0,
                          "Crypt::OpenSSL::RSA" => 0,
                          "File::Slurp" => 0,
                          "JSON" => 0,
                          "common::sense" => 0
                         },
  );
$build->create_build_script;
