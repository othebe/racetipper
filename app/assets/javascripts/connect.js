/* Facebook connect */
   
//Title:		facebook_login
//Description:	Logs a user in via Facebook
function facebook_login() {
	FB.login(function(response) {
		if (response.authResponse) {
			// connected
			access_token = response.authResponse.accessToken;
			$.get('/users/login_with_facebook', {access_token:access_token}, function(login_response) {
				if (login_response.success) {
					window.location.hash = '#competitions/index';
					window.location.reload();
				} else alert(login_response.msg);
			});
		} else {
			// cancelled
		}
	}, {
		scope: 'email'
	});
}

//Title:		link_fb
//Description:	Links a Facebook accout to an already logged in user
function link_fb() {
	FB.login(function(response) {
		if (response.authResponse) {
			// connected
			access_token = response.authResponse.accessToken;
			$.get('/users/link_fb_to_user', {access_token:access_token}, function(login_response) {
				if (login_response.success)
					window.location.reload();
				else alert(login_response.msg);
			});
		} else {
			// cancelled
		}
	}, {
		scope: 'email'
	});
}