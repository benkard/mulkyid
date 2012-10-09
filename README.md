<!--- -*- mode: markdown; coding: utf-8 -*- --->

# Mulky IMAP BrowserID Primary

## Introduction

This software provides a simple Mozilla Persona primary (also called
an *authenticating party* or an *identity provider*) based on an existing
local IMAP server setup.  Users use their IMAP login and password to
authenticate themselves as the owner of their email address.

The primary is implemented as a set of simple CGI scripts.


## Assumptions About Your E-Mail Setup

This software assumes that email addresses can be resolved to user
names by way of `/etc/aliases` and that the user names provided
therein are identical to those accepted by your IMAP server for
purposes of authenticating.  If no `/etc/aliases` file exists, the
IMAP server needs to accept the name part of an e-mail address as a
user name.

If this is not true for your setup, you will need to hack the source
code.


## Installation

### Prerequisites

The following CPAN modules need to be installed:

 * `CGI`
 * `CGI::Fast`
 * `CGI::Session`
 * `common::sense`
 * `Crypt::OpenSSL::RSA`
 * `Crypt::OpenSSL::Bignum`
 * `File::Slurp`
 * `JSON`
 * `MIME::Base64`
 * `Mail::ExpandAliases`
 * `Mail::IMAPTalk`
 * `Modern::Perl`
 * `Time::HiRes`
 * `LWP::Simple` (for the setup process only)

### Key Setup and jQuery Download

In order to generate an RSA private key and download necessary
third-party components, run `setup.pl`.

`setup.pl` will also generate a `browserid.json` file and prompt you
to put it wherever your web server will be able to serve it as
`/.well-known/browserid`.


## License

Copyright 2012, Matthias Andreas Benkard.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
