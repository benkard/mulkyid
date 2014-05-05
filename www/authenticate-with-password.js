jQuery(function($) {
    var getParameterByName = function(name) {
        // https://stackoverflow.com/a/5158301
        var match = RegExp('[?&]' + name + '=([^&]*)').exec(window.location.search);
        return match && decodeURIComponent(match[1].replace(/\+/g, ' '));
    };

    var email = getParameterByName('email');
    $('#email').val(email);

    var onAuthentication = function() {
        var password = $('#password').val();
        $.ajax({
            type: 'POST',
            url: '/browserid/login.pl',
            dataType: 'json',
            data: { email: email, password: password },
            success: function(sig, status, xhr) {
                console.log("Login successful!");
                navigator.id.completeAuthentication();
            },
            error: function(reason, status, xhr) {
                navigator.id.raiseAuthenticationFailure(reason.responseText);
            }
        });
        return false;
    };

    var onCancel = function() {
        navigator.id.cancelAuthentication();
    };

    $('#auth-form').submit(onAuthentication);
    $('.cancel').click(onCancel);
});
