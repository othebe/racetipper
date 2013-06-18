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
	this.weeks = $(elt).find('.weeks');
	this.days = $(elt).find('.days');
	this.hours = $(elt).find('.hours');
	this.minutes = $(elt).find('.minutes');
	this.seconds = $(elt).find('.seconds');
	
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
	
	this.weeks.html((arr['weeks']>0)?arr['weeks']:'--');
	this.days.html((arr['days']>0)?arr['days']:'--');
	this.hours.html((arr['hours']>0)?arr['hours']:'--');
	this.minutes.html((arr['minutes']>0)?arr['minutes']:'--');
	this.seconds.html((arr['seconds']>0)?arr['seconds']:'--');
	
	return;
}

//Convert remaining_sec -> remaining_arr
function parse_seconds(seconds) {
	remaining_arr = {};
	//seconds -= WEEK*(remaining_arr['weeks'] = Math.floor(seconds / WEEK));
	seconds -= DAY*(remaining_arr['days'] = Math.floor(seconds / DAY));
	seconds -= HOUR*(remaining_arr['hours'] = Math.floor(seconds / HOUR));
	seconds -= MINUTE*(remaining_arr['minutes'] = Math.floor(seconds / MINUTE));
	remaining_arr['seconds'] = seconds;
	
	return remaining_arr;
}

