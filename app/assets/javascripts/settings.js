/* Settings page */

//Title:		change_password
//Description:	Checks for matching passwords, and makes call to change password
function change_password_from_temporary() {
	var password = $('input[name=new_password]').val();
	var verify_password = $('input[name=verify_password]').val();
	
	//Passwords dont match
	if (password != verify_password) {
		alert('Your passwords do not match.');
		return false;
	}
	
	$.post('/users/change_password', {password:password}, function(response) {
		if (!response.success)
			alert(response.msg);
		else window.location.href = '/';
	});
}

//Title:		change_password
//Description:	Checks for matching passwords, and makes call to change password
function change_password() {
	var password = $('input[name=new_password]').val();
	var verify_password = $('input[name=verify_password]').val();
	
	//Passwords dont match
	if (password != verify_password) {
		alert('Your passwords do not match.');
		return false;
	}
	
	$.post('/users/change_password', {password:password}, function(response) {
		if (!response.success)
			alert(response.msg);
	});
}