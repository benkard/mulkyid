#! /bin/sh

WWWUSER=www

# Download jQuery.
mkdir -p jquery
wget -O jquery/jquery.js http://code.jquery.com/jquery-1.7.2.min.js

# Generate the private key.
openssl genpkey -algorithm rsa -out rsa2048.pem -pkeyopt rsa_keygen_bits:2048

# Install the private key.
mkdir -p /etc/mulkid
mv rsa2048.pem /etc/mulkid/
chmod go=      /etc/mulkid/rsa2048.pem
chown $WWWUSER /etc/mulkid/rsa2048.pem

# Generate spec file.
./generate_specfile.pl >browserid.json
echo "Please put browserid.json where it will be served as"
echo "    https://<whatever>/.well-known/browserid"
echo "with a content type of"
echo "    application/json"
echo "."
