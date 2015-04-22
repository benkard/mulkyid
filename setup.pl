#! /usr/bin/env perl
system "perl Build.PL";
system "perl Build installdeps";
system "perl Build configure";
system "perl Build";

