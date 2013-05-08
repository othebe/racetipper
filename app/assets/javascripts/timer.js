var MINUTE = 60;
var HOUR = 60*MINUTE;
var DAY = 24*HOUR;
var WEEK = 7*DAY;

var remaining_secs = 0;
var current_timer = null;

var CountdownTimer = function(elt, seconds) {
	this.timer_elt = $(elt);
	this.remaining_secs = seconds;
	
	//Get span elements
	this.weeks = $(elt).find('span#weeks');
	this.days = $(elt).find('span#days');
	this.hours = $(elt).find('span#hours');
	this.minutes = $(elt).find('span#minutes');
	this.seconds = $(elt).find('span#seconds');
	
	//Start timer
	this.start_timer();
}

//Start the countdown
CountdownTimer.prototype.start_timer = function() {
	var obj = this;
	if (current_timer != null) clearInterval(current_timer);
	current_timer = setInterval(function() {
		if (obj.remaining_secs > 0) obj.remaining_secs--;
		time_arr = parse_seconds(obj.remaining_secs);
		obj.display_time(time_arr);
	},1000);
}

//Display the time
CountdownTimer.prototype.display_time = function(arr) {
	var str = [];
	
	//Weeks
	var weeks = arr['weeks'];
	if (weeks > 0) {
		str.push(arr['weeks']);
		if (weeks > 1)
			str.push(' weeks,');
		else str.push(' week, ');
	} else this.weeks.hide();
	
	//Days
	var days = arr['days'];
	if (days > 0) {
		str.push(arr['days']);
		if (days > 1)
			str.push(' days,');
		else str.push(' day, ');
	} else this.days.hide();
	
	//Hours
	var hours = arr['hours'];
	if (hours < 10) hours = "0"+hours;
	str.push(hours, ':');
	
	//Minutes
	var minutes = arr['minutes'];
	if (minutes < 10) minutes = "0"+minutes;
	str.push(minutes, ':');
	
	//Seconds
	var seconds = arr['seconds'];
	if (seconds < 10) seconds = "0"+seconds;
	str.push(seconds);
	
	this.timer_elt.html(str.join(''));
}

//Convert remaining_sec -> remaining_arr
function parse_seconds(seconds) {
	remaining_arr = {};
	seconds -= WEEK*(remaining_arr['weeks'] = Math.floor(seconds / WEEK));
	seconds -= DAY*(remaining_arr['days'] = Math.floor(seconds / DAY));
	seconds -= HOUR*(remaining_arr['hours'] = Math.floor(seconds / HOUR));
	seconds -= MINUTE*(remaining_arr['minutes'] = Math.floor(seconds / MINUTE));
	remaining_arr['seconds'] = seconds;
	
	return remaining_arr;
}

