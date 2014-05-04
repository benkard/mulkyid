#! /usr/bin/env perl
system "perl build.PL";
system "perl Build installdeps";
system "perl Build";

