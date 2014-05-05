jQuery(function($) {
  navigator.id.beginAuthentication(function(email) {
    var escapedEmail = encodeURIComponent(email);
    window.location = 'authenticate.pl?email=' + escapedEmail;
  });
});
