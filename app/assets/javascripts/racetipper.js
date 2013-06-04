$(document).ready(function(event) {
	
});

//Title:		login
//Description:	Log a user in
var logging_in = false;
function login(elt) {
	if (logging_in) return;
	
	var parent = $(elt).parent();
	if ($(parent).find('input[name=email]').length==0) parent = $(parent).parent();
	$(elt).removeClass('yellow').addClass('gray');
	$(parent).find('div.loading').show();
	
	data = {};
	data['email'] = $(parent).find('input[name=email]').val();
	data['password'] = $(parent).find('input[name=password]').val();
	
	$.post('/users/login', {data:data}, function(response) {
		if (response.success) {
			window.location.reload();
		} else alert(response.msg);
		
		logging_in = false;
		$(elt).removeClass('gray').addClass('yellow');
		$(parent).find('div.loading').hide();
	});
	
	return;
}

//Title:		logout
//Description:	Log out user
function logout() {
	window.location.href = '/users/logout';
}

//Title:		signup
//Description:	Sign a new user up
var signing_up = false;
function signup(elt) {
	if (signing_up) return;
	
	var parent = $(elt).parent();
	if ($(parent).find('input[name=email]').length==0) parent = $(parent).parent();
	$(elt).removeClass('yellow').addClass('gray');
	$(parent).find('div.loading').show();
	
	var data = {};
	data['firstname'] = $(parent).find('input[name=firstname]').val();
	data['lastname'] = $(parent).find('input[name=lastname]').val();
	data['email'] = $(parent).find('input[name=email]').val();
	data['password'] = $(parent).find('input[name=password]').val();
	
	$.post('/users/create', {data:data}, function(response) {
		if (response.success) {
			window.location.reload();
		} else alert (response.msg);
		
		signing_up = false;
		$(elt).removeClass('gray').addClass('yellow');
		$(parent).find('div.loading').hide();
	});
	
	return;
}

//Title:		load_results
//Description:	Load race results
//Params:		elt - Object that triggers a results load
function load_results(elt) {
	var parent = $(elt).parent();
	var load_img = $(parent).find('img.loading');
	var load_option = $(parent).find('select option:selected');
	var results_table = $(parent).find('table');
	
	var url = '';
	var load_data_id = $(load_option).val();
	var load_data_type = $(load_option).attr('data-type');
	if (load_data_type == 'race') url = '/races/get_results/'+load_data_id;
	if (load_data_type == 'stage') url = '/stages/get_results/'+load_data_id;
	
	$(load_img).show();
	$.get(url, {}, function(response) {
		$(results_table).find('tbody').empty();
		if (response.results.length > 0) {
			for (i=0; i< response.results.length; i++) {
				result = response.results[i];
				
				var time_formatted = (result.disqualified==null)?result.time_formatted:result.disqualified;
				var bonus_time_formatted = (result.disqualified==null)?result.bonus_time_formatted:'---';
				var gap_formatted = (result.disqualified==null)?result.gap_formatted:'---';
				var kom_points = (result.disqualified==null)?result.kom_points:'---';
				var sprint_points = (result.disqualified==null)?result.sprint_points:'---';
				
				var row = $('<tr></tr>');
				$(row).append(['<td>',result.rank,'</td>'].join(''));
				$(row).append(['<td>',result.rider_name,'</td>'].join(''));
				$(row).append(['<td>',time_formatted,'</td>'].join(''));
				$(row).append(['<td>',bonus_time_formatted,'</td>'].join(''));
				$(row).append(['<td>',gap_formatted,'</td>'].join(''));
				$(row).append(['<td>',kom_points,'</td>'].join(''));
				$(row).append(['<td>',sprint_points,'</td>'].join(''));
				
				$(results_table).find('tbody').append(row);
			}
		}
		
		$(load_img).hide();
		$(results_table).show();
		moduleTextPage(true);
	});
}

//Title:		load_leaderboard
//Description:	Load leaderboard
//Params:		elt - Object that triggers a results load
function load_leaderboard(elt) {
	var parent = $(elt).parent();
	var load_img = $(parent).find('img.loading');
	var load_option = $(parent).find('select option:selected');
	var results_table = $(parent).find('table');
	
	var competition_id = $(parent).find('#competition_id').val();
	var url = '/competitions/get_competition_leaderboard/'+competition_id;
	var load_data_id = $(load_option).val();
	var load_data_type = $(load_option).attr('data-type');
	
	$(load_img).show();
	$.get(url, {id:load_data_id, group_type:load_data_type, group_id:load_data_id}, function(response) {
		$(results_table).find('tbody').empty();
		if (response.leaderboard.length > 0) {
			for (i=0; i< response.leaderboard.length; i++) {
				result = response.leaderboard[i];
				if (load_data_type == 'race') {
					var click_scr = "load_page('#competitions/show_tips/"+competition_id+"?uid="+result.user_id+"')";
					selection = '<div class="button" onclick="'+click_scr+'"><span>VIEW TIPS</span></div>';
				}
				else {
					selection = result.tip[0].name
					if (result.is_default) selection = selection + ' <span style="font-style:italic;">(Default)<span>';
				}
				
				var row = $('<tr></tr>');
				$(row).append(['<td>',(i+1),'</td>'].join(''));
				$(row).append(['<td>',result.username,'</td>'].join(''));
				$(row).append(['<td>',result.time_formatted,'</td>'].join(''));
				$(row).append(['<td>',result.gap_formatted,'</td>'].join(''));
				$(row).append(['<td>',result.kom,'</td>'].join(''));
				$(row).append(['<td>',result.sprint,'</td>'].join(''));
				$(row).append(['<td>',selection,'</td>'].join(''));
				
				$(results_table).find('tbody').append(row);
			}
		}
		
		$(load_img).hide();
		$(results_table).show();
		moduleTextPage(true);
	});
}

//Title:		show_tip_sheet
//Description:	Show tip sheet for a competition stage
//Params:		elt - Object that triggers a tip sheet load
function show_tip_sheet(elt) {
	var parent = $(elt).parent().parent();
	var load_img = $(parent).find('img.loading');
	var load_option = $(parent).find('select option:selected');
	var data_elt = $(parent).find('div.data').empty();
	
	var competition_id = $(load_option).attr('competition_id');
	var stage_id = $('#tip_sheet_stages').val();
	var url = '/competitions/get_tip_sheet/'+competition_id;
	
	$(load_img).show();
	$.get(url, {stage_id:stage_id}, function(response) {
		if (response.tipsheet.length > 0) {
			$(response.tipsheet).each(function(ndx, data) {
				var container = $('<fieldset></fieldset>');
				$(container).append('<legend>'+data.team_name+'</legend>');
				
				//Riders
				for(i=0; i<data.riders.length; i++) {
					var rider = data.riders[i];
					var not_allowed = '';
					var cb_allow = '';
					var label_allow = '';
					var cb_checked = '';

					//Allowed?
					if (!rider.allowed.allowed) {
						cb_allow = ' disabled="disabled" ';
						label_allow = 'color:lightgray;';
						not_allowed = ' ('+rider.allowed.reason+')';
					}
					
					//Current selection?
					selected_stage = '';
					if (rider.selected) {
						cb_checked = ' checked="checked" ';
						selected_stage = ' ('+response.stage.name+')';
					}
					
					var line = $(['<input type="checkbox" id="',rider.rider_id,'" val="',rider.rider_id,'"',cb_allow,cb_checked,'><label for="',rider.rider_id,'" style="',label_allow,'">',rider.rider_name,' [',rider.rider_number,']',not_allowed,'</label><span class="selection_verify" id="',rider.rider_id,'">',selected_stage,'</span></br>'].join(''));
					$(container).append(line);
				}
				
				$(data_elt).append(container);
			})
		}
		
		$(data_elt).find('input[type=checkbox]').unbind('click');
		$(data_elt).find('input[type=checkbox]').click(function(event) {
			$('input[type=checkbox]').removeAttr('checked');
			$(this).attr('checked', true);
			rider_id = $(this).attr('id');
			save_tip(competition_id, stage_id, rider_id);
		});
		
		//Set timer
		if (response.stage.remaining > 0) {
			new CountdownTimer('div.countdown', response.stage.remaining);
		}

		$(load_img).hide();
		moduleTextPage(true);
	});
}

//Title:		show_selection_sheet
//Description:	Show selection sheet for a competition stage. Only selections, no tipping.
//Params:		elt - Object that triggers a selection sheet load
function show_selection_sheet(elt) {
	var parent = $(elt).parent();
	var load_img = $(parent).find('img.loading');
	var load_option = $(parent).find('select option:selected');
	var data_elt = $(parent).find('div.data').empty();
	
	var competition_id = $(load_option).attr('competition_id');
	var race_id = $('#selection_sheet_races').val();
	var url = '/competitions/get_selection_sheet/'+competition_id;
	
	$(load_img).show();
	$.get(url, {race_id:race_id}, function(response) {
		if (response.selection_sheet.length > 0) {
			$(response.selection_sheet).each(function(ndx, data) {
				var container = $('<fieldset></fieldset>');
				$(container).append('<legend>'+data.team_name+'</legend>');
				
				//Riders
				for(i=0; i<data.riders.length; i++) {
					var rider = data.riders[i];
					var cb_checked = '';
					var status = '';
					
					//Disqualified
					if (rider.disqualified != null) {
						status = ' ('+rider.disqualified+')';
					}
					//Selected for stage
					else if (rider.stage != null) {
						cb_checked = 'checked="checked"';
						status = ' ('+rider.stage+')';
					}
					
					var line = $(['<input type="checkbox" ',cb_checked,' disabled="disabled"></input><label style="color:lightgray;">',rider.rider_name,' [',rider.rider_number,']',status,'</label></br>'].join(''));
					$(container).append(line);
				}
				
				$(data_elt).append(container);
			})
		}
		
		$(load_img).hide();
		moduleTextPage(true);
	});
}

//Title:		save_tip
//Description:	Save a tip
function save_tip(competition_id, stage_id, rider_id, elt) {
	//Loader
	var loader_source   = $('#tip-sheet-loader-template').html();
	var loader_template = Handlebars.compile(loader_source);
	var loader_html = loader_template();
	
	//Success
	var success_source   = $('#tip-sheet-success-template').html();
	var success_template = Handlebars.compile(success_source);
	var success_html = success_template();
	
	$(elt).append(loader_html);
	
	$.post('/competitions/save_tip/'+competition_id, {stage_id:stage_id, rider_id:rider_id}, function(response) {
		if (!response.success) 
			alert(response.msg);
		else {
			$('div#tip-sheet div.rider.selected').removeClass('selected');
			$(elt).find('img.loader').remove();
			$(elt).append(success_html);
			$(elt).addClass('selected');
			
			//Change chosen rider name
			$(document).find('.selected-rider-name.'+stage_id).html(response.data['rider_name']);
			
			//Remove unselected message on header if any
			var header_container = $('.col.add-tip.bold');
			$(header_container).find('.red').prepend("You've tipped ").before('<img alt="Tick" src="/assets/tick.png" style="float:left; margin-right:5px; margin-top:10px;">');
			$(header_container).find('.red').removeClass('red');
			
			//Remove unselected message on floating bar if any
			var header_container = $('tr.'+stage_id);
			$(header_container).find('.name-td.yellow').removeClass('yellow');
			$(header_container).find('td.red').removeClass('red').html('<img alt="Pencil" src="/assets/pencil.png">');
		}
	});
}

//Title:		Join a competition
//Description:	Join a competition
var joining_competition = false;
function join_competition(competition_id, elt) {
	if (joining_competition) return;
	
	joining_competition = true;
	$(elt).removeClass('yellow').addClass('gray');
	
	var url = '/competitions/join/'+competition_id;
	
	$.post(url, {}, function(response) {
		if (response.success) {
			location.reload();
		} else {
			alert(response.msg);
			$(elt).removeClass('gray').addClass('yellow');
			joining_competition = false;
		}
	});
}

//Title:		leave_competition
//Description:	User leaves a competition
//Params:		competition_id - Competition ID
//				user_id - User to kick. Null for current user.
function leave_competition(competition_id, user_id) {
	if (!confirm("Are you sure you want to leave this competition?")) return;
	
	var url = '/competitions/kick/'+competition_id;
	$.post(url, {user_id:user_id}, function(response) {
		if (response.success) 
			window.location.href = '/';
		else alert(response.msg);
	});
}

//Title:		load_race_results
//Description:	Load race results on race page
//Params:		elt - Object that triggers a results load
function load_race_results(elt) {
	var parent = $(elt).parent();
	var load_img = $(parent).find('img.loading');
	var load_option = $(parent).find('select option:selected');
	var info_table = $(parent).find('div.info table');
	var results_table = $('div.competition_results table');

	var url = '';
	var load_data_id = $(load_option).val();
	var load_data_type = $(load_option).attr('data-type');
	if (load_data_type == 'race') url = '/races/get_results/'+load_data_id;
	if (load_data_type == 'stage') url = '/stages/get_results/'+load_data_id;
	
	$(load_img).show();
	$.get(url, {}, function(response) {
		//General info
		$(info_table).find('td.data').empty();
		$(info_table).find('td.label').hide();
		//Race
		if (load_data_type=='race') {
			$(info_table).find('tr.season td.data').html(response.race.season);
			$(info_table).find('tr.season td.label').show();
			$(parent).find('div.description').empty().html(response.race.description);
		}
		//Stage
		if (load_data_type=='stage') {
			if (response.stage.profile != null) {
				$(info_table).find('tr.profile td.data').html(['<a href="',response.stage.profile,'" target="_blank">View</a>'].join(''));
				$(info_table).find('tr.profile td.label').show();
			}
			
			$(info_table).find('tr.starts_on td.data').html(response.stage.starts_on);
			$(info_table).find('tr.starts_on td.label').show();
			
			$(info_table).find('tr.start_location td.data').html(response.stage.start_location);
			$(info_table).find('tr.start_location td.label').show();
			
			$(info_table).find('tr.end_location td.data').html(response.stage.end_location);
			$(info_table).find('tr.end_location td.label').show();
			
			$(info_table).find('tr.distance td.data').html(response.stage.distance);
			$(info_table).find('tr.distance td.label').show();
			
			$(parent).find('div.description').empty().html(response.stage.description);
		}
		
		
		//Results table
		$(results_table).find('tbody').empty();
		if (response.results.length > 0) {
			for (i=0; i< response.results.length; i++) {
				result = response.results[i];
				
				var time_formatted = (result.disqualified==null)?result.time_formatted:result.disqualified;
				var bonus_time_formatted = (result.disqualified==null)?result.bonus_time_formatted:'---';
				var gap_formatted = (result.disqualified==null)?result.gap_formatted:'---';
				var kom_points = (result.disqualified==null)?result.kom_points:'---';
				var sprint_points = (result.disqualified==null)?result.sprint_points:'---';
				var rider_name = result.rider_name
				
				var row = $('<tr></tr>');
				$(row).append(['<td>',result.rank,'</td>'].join(''));
				$(row).append(['<td>',rider_name,'</td>'].join(''));
				$(row).append(['<td>',time_formatted,'</td>'].join(''));
				$(row).append(['<td>',bonus_time_formatted,'</td>'].join(''));
				$(row).append(['<td>',gap_formatted,'</td>'].join(''));
				$(row).append(['<td>',kom_points,'</td>'].join(''));
				$(row).append(['<td>',sprint_points,'</td>'].join(''));
				
				$(results_table).find('tbody').append(row);
			}
		}
		
		$(load_img).hide();
		$(info_table).show();
		$(results_table).show();
		moduleTextPage(true);
	});
}

//Title:		load_home_race_results
//Description:	Load race results on the home page
//Params:		elt - Object that triggered the load
//				id - Race ID
function load_home_race_results(elt, id) {
	var url = '/races/get_results/'+id;
	var results_container = $(elt).parent().find('div.results').empty();
	var max_results = 4;
	$.get(url, {}, function(response) {
		results_container.empty();
		results = response.results;
		for (i=0; i<results.length; i++) {
			if (i >= max_results) break;
			var result = results[i];
			var time_formatted = (result.disqualified==null)?result.time_formatted:result.disqualified;
			var div_elt = $('<div></div>');
			$(div_elt).append('<span>'+result.rider_name+'</span>');
			$(div_elt).append('<span>'+time_formatted+'</span>');
			
			$(results_container).append(div_elt);
		}
		
		$(elt).hide();
	});
}

//Title:		show_default_riders
//Description:	Show default riders for a race in a competition
//Params:		elt - Object that triggered the load
//				id - Competition ID
function show_default_riders(elt, id) {
	var url = '/competitions/get_default_riders/'+id;
	var race_id = $('#default_rider_races').val();
	var rider_container = $('#default_rider_data');
	
	$.get(url, {race_id:race_id}, function(response) {
		$(response.default_riders).each(function(ndx, default_rider) {
			var row = $('<div></div>');
			note = default_rider.disqualified || default_rider.selected;
			if (note != null) {	
				$(row).css('color', 'lightgray');
				$(row).html(['<span style="text-decoration:line-through;">',default_rider.name,'</span>',' (',note,')'].join(''));
			} else $(row).html(['<span>',default_rider.name,'</span>'].join(''));
			
			$(rider_container).append(row);
		});
		moduleTextPage(true);
	});
}

//Title:		setup_crop
//Description:	Setup image cropping
var scrollbar_set = false;
var orig_width = 0;
var orig_height = 0;
var aspect_w = 516;
var aspect_h = 167;
var jcrop_obj = '';
function setup_crop(evt, elt) {
	aspect_w = $(elt).attr('width');
	aspect_h = $(elt).attr('height');
	
	// Check for the various File API support.
	if (window.File && window.FileReader && window.FileList && window.Blob) {
		// Great success! All the File APIs are supported.
		var files = evt.target.files; // FileList object

		// Loop through the FileList and render image files as thumbnails.
		for (var i = 0, f; f = files[i]; i++) {

			// Only process image files.
			if (!f.type.match('image.*')) {
			continue;
			}

			reader = new FileReader();

			// Closure to capture the file information.
			reader.onload = (function(theFile) {
				$('#image_name').val(theFile.name);
				return function(e) {
					// Get original dimensions
					var orig_img = new Image();
					orig_img.src = e.target.result;
					orig_img.onload = function() {
						orig_width = orig_img.width;
						orig_height = orig_img.height;
					};
					
					//JCrop
					if (jcrop_obj != '') jcrop_obj.destroy();
					var img = ['<img class="thumb" id="jcrop_target" src="', e.target.result, '"/>'].join('');
					$('.image_upload #jcrop_target').remove();
					$('.image_upload').append(img);
					$('#jcrop_target').Jcrop({
						onChange: show_preview,
						onSelect: show_preview,
						aspectRatio: (aspect_w/aspect_h)
					}, function() {
						jcrop_obj = this;
					});
					
					//Preview
					$('#preview_label').show();
					$('.image_preview').empty().html($(img).attr('id', 'jcrop_preview'));
				};
			})(f);

			// Read in the image file as a data URL.
			reader.readAsDataURL(f);
		}
	} else {
	  alert('The File APIs are not fully supported in this browser.');
	}
}

//Title:		show_preview
//Description:	Show crop preview
function show_preview(coords) {
	if (!scrollbar_set && typeof window.moduleUpdate_text_page == 'function') moduleUpdate_text_page();
	scrollbar_set = true;
	
	var jcrop_img_width = $('#jcrop_target').width();
	var jcrop_img_height = $('#jcrop_target').height();
	
	//Save coords for server
	$('#crop_w').val(orig_width / jcrop_img_width * coords.w);
	$('#crop_h').val(orig_height / jcrop_img_height * coords.h);
	$('#crop_x').val(orig_width / jcrop_img_width * coords.x);
	$('#crop_y').val(orig_height / jcrop_img_height * coords.y);
	
	//Setup coords for preview
	var rx = jcrop_img_width / coords.w;
	var ry = jcrop_img_height / coords.h;
	var width = Math.round(rx * aspect_w);
	var height = Math.round(ry * aspect_h);
	var marginLeft =  Math.round(rx * coords.x);
	var marginTop = Math.round(ry * coords.y);

	$('.image_preview img').css({
		width: width + 'px',
		height: height + 'px',
		marginLeft: '-' + marginLeft + 'px',
		marginTop: '-' + marginTop + 'px'
	});
}

//Title:		save_competition
//Description:	Save a competition
var saving_competition = false;
function save_competition() {
	if (saving_competition) return;
	
	var data_container = $('#new-competition-fancybox');
	
	var data = {};
	data['id'] = $(data_container).find('.competition-id').val();
	data['race_id'] = $(data_container).find('.race-id').val();
	data['competition_name'] = $(data_container).find('.competition-name').val();
	data['competition_description'] = $(data_container).find('.competition-description').val();
	data['open_to'] = $(data_container).find('input[name=privacy]:checked').val();
	data['invitations'] = $(data_container).find('.invitations').val();
	
	$(data_container).find('.footer .loading').show();
	$(data_container).find('.footer .btn').removeClass('yellow').addClass('gray');
	
	saving_competition = true;
	
	$.post('/competitions/save_competition', {data:data}, function(response) {
		$(data_container).find('.footer .loading').hide();
		if (!response.success) {
			alert(response.msg);
			$(data_container).find('.footer .btn').removeClass('gray').addClass('yellow');
		} else {
			$(data_container).find('.footer .success').show();
		}
		saving_competition = false;
	});
	return false;
}

//Title:		load_more_competitions
//Description:	Loads more competitions
function load_more__competitions(elt) {
	var limit = 8;
	var container = $('#module-columns-holder');
	var num_loaded = $(container).find('div.competition').length;
	var template = $(container).find('div.competition').first();
	
	$(elt).hide();
	$(elt).parent().find('img.loading').show();
	
	$.get('/competitions/get_more_competitions.json', {limit:limit, offset:num_loaded}, function(response) {
		competitions = response.competition_data;
		for (i=0; i<competitions.length; i++) {
			var competition = competitions[i];
			var completion = (competition.is_complete)?'Completed':'Open';
			var copy = template.clone();
			
			$(copy).attr('data-url', '#competitions/'+competition.id);
			$(copy).find('img').attr('src', competition.image_url);
			$(copy).find('div.thumb-tag h1').html(competition.name);
			$(copy).find('div.thumb-tag h2').html(completion);
			$(container).append($(copy).fadeIn());
			animateThumb($(copy).find('img'));
		}
		$(elt).show();
		$(elt).parent().find('img.loading').hide();
		modulePageColumns();
	});
}

//Title:		generate_temp_password
//Description:	Generate temporary password
function generate_temp_password(elt) {
	$(elt).hide();
	$('img.loading.forgot_password').show();
	
	$.get('/users/reset_password', {}, function(response) {
		$('.forgot_password_loaded').show();
		$('.forgot_password_loading').hide();
		alert(response.msg);
		
		$(elt).show();
		$('img.loading.forgot_password').hide();
	});
}

//Title:		submit_feedback
//Description:	Submit feedback
function submit_feedback(elt) {
	var title = $('input[name=title]').val();
	var description = $('textarea[name=description]').val();
	
	$(elt).hide();
	$('.loading').show();
	
	$.post('/bugs/submit_feedback', {title:title, description:description}, function(response) {
		alert(response.msg);
		
		$(elt).show();
		$('.loading').hide();
	});
}

//Title:		forgot_password
//Description:	User forgot password. Mail them one.
function forgot_password(elt) {
	var email = $('input[name=reset_email]').val();
	
	$(elt).hide();
	$('.loading.password_reset').show();
	
	$.post('/users/reset_password_from_email', {email:email}, function(response) {
		alert(response.msg);
		$(elt).show();
		$('.loading.password_reset').hide();
	});
}

//Title:		load_comments
//Description:	Loads Facebook comments and fixes scrollbars
function load_comments() {
	$('.fb-comments').attr('data-width', document.width * 0.6);
	FB.XFBML.parse();
	moduleTextPage(true);
}

//Title:		get_user_race_data
//Description:	Gets data for a user about a race
//Params:		user_id - User requesting data
//				race_id - Race ID
//				elt - Element triggering event
function get_user_race_data(user_id, race_id, elt) {
	$.get('/competitions/user_race_data/'+race_id, {user_id:user_id}, function(response) {
		var race_competition_source   = $('#race-competitions-template').html();
		var race_competition_template = Handlebars.compile(race_competition_source);
		
		var competition_source = $('#race-competitions-data-template').html();
		var competition_template = Handlebars.compile(competition_source);
		
		//Parse response
		var remaining = parseInt(response.race['next_stage_remaining']);
		var race_competition_context = {};
		race_competition_context['completed'] = (remaining>0);
		race_competition_context['race_name'] = response.race['race_name'];
		race_competition_context['next_stage_name'] = response.race['next_stage_name'];
		
		//Get HTML
		var html = race_competition_template(race_competition_context);
		
		//Put HTML into document
		if (elt != null) {
			var header = $(elt).parent().parent();
			var container = $(header).parent();
			
			//Timer
			var timer = $(html).find('div.timer');
			$(header).find('.race-details').prepend($(timer).fadeIn());
			if (remaining > 0) {
				new CountdownTimer($(header).find('div.timer'), remaining);
			}
			
			//Competition data
			$(response.competition).each(function(ndx, elt) {
				//Postfix
				postfix = 'th';
				var rank_str = elt['rank'].toString();
				var ending = parseInt(rank_str.charAt(rank_str.length-1));
				
				if ([1].indexOf(ending)>=0) 
					postfix = 'st';
				else if ([2].indexOf(ending)>=0) 
					postfix = 'nd';
				else if ([3].indexOf(ending)>=0) 
					postfix = 'rd';
				
				elt['postfix'] = postfix;
				elt['completed'] = !(remaining>0);
				console.log(elt);
				var competition_html = competition_template(elt);
				$(container).find('table.competitions').append(competition_html);
			});
			
			//More competitions
			var competition_box_source = $('#competition-box-template').html();
			var competition_box_template = Handlebars.compile(competition_box_source);
			$(response.more_competitions).each(function(ndx, elt) {
				var competition_box_html = competition_box_template(elt);
				$(container).find('.new-competition').after(competition_box_html);
			});
		}
		
		$(elt).hide();
	});
}

var competitions_table = 'tipping';
var competition_race_leaderboard_initialized = false;
//Title:		show_tipping_leaderboard_from_competition
//Description:	Show the tipping leaderboard table from the competitions page
function show_tipping_leaderboard_from_competition() {
	if (competitions_table=='tipping') return;
	competitions_table = 'tipping';
	
	$('table.data').removeClass('grayblack');
	$('table.data').addClass('blue');
	$('table.data tr.race').hide();
	$('table.data tr.tipping').show();
	
	$("table.data").tablesorter(); 
}
//Title:		show_race_leaderboard_from_competition
//Description:	Show the race leaderboard table from the competitions page
function show_race_leaderboard_from_competition(race_id) {
	if (competitions_table=='race') return;
	competitions_table = 'race';
	
	if (!competition_race_leaderboard_initialized) {
		$('table.selector img.loading').show(); 
		$.get('/races/get_results/'+race_id, {}, function(response) {
			var source   = $('#competition-race-result-template').html();
			var template = Handlebars.compile(source);
		
			$(response.results).each(function(ndx, result) {
				result['ndx'] = ndx+1;
				var row = template(result);
				$('table.data tbody').append(row);
			});
			$('table.data').removeClass('blue');
			$('table.data').addClass('grayblack');
			
			$('table.data tr.tipping').hide();
			$('table.data tr.race').show();
			
			$("table.data").trigger("update"); 
			
			$('table.selector img.loading').hide(); 
			competition_race_leaderboard_initialized = true;
		});
	} else {
		$('table.data').removeClass('blue');
		$('table.data').addClass('grayblack');
		$('table.data tr.tipping').hide();
		$('table.data tr.race').show();
	}
}

//Title:		load_stage_info
//Description:	Loads stage info into the competitions screen
var loading_stage_info = false;
var current_stage_id = null;
function load_stage_info(stage_id, competition_id) {
	if (loading_stage_info) return;
	if (current_stage_id==stage_id) return;
	
	current_stage_id = stage_id;
	loading_stage_info = true;
	$('#content-with-nav').addClass('loading-overlay');
	
	$.get('/stages/information/'+stage_id, {competition_id:competition_id}, function(stage_info) {
		stage_leaderboard_type = 'tipping';
		stage_leaderboard_scope = 'stage';
		stage_leaderboard_initialized = false;
		stage_leaderboard_loaded_tables = {'tipping':{}, 'race':{}};
		
		stage_info['countdown'] = (stage_info['remaining']>0);
		
		stage_info['stage_type_flat'] = (stage_info['stage_type']=='F');
		stage_info['stage_type_medium_mountain'] = (stage_info['stage_type']=='MM');
		stage_info['stage_type_high_mountain'] = (stage_info['stage_type']=='HM');
		stage_info['stage_type_mountain_finish'] = (stage_info['stage_type']=='MF');
		stage_info['stage_type_itt'] = (stage_info['stage_type']=='ITT');
		stage_info['stage_type_ttt'] = (stage_info['stage_type']=='TTT');
		
		//Stage overview
		var stage_header_source   = $('#stage-header-template').html();
		var stage_header_template = Handlebars.compile(stage_header_source);
		var stage_header_html = stage_header_template(stage_info);
		
		$('#content-with-nav').hide();
		$('#content-with-nav').html(stage_header_html);
		$('#content-with-nav').fadeIn();
		
		//Stage images
		if (stage_info['stage_images'].length > 0) {
			var stage_image_slider_source = $('#stage-image-slider-template').html();
			var stage_image_slider_template = Handlebars.compile(stage_image_slider_source);
			var stage_image_slider_html = stage_image_slider_template(stage_info);
			$('#content-with-nav').append(stage_image_slider_html);
			$('.stage-images').bjqs({
				height      : 320,
				width       : 620,
				showcontrols : false,
				responsive  : true,
				automatic: false,
			});
		}
		
		//Tipping reports
		var tipping_report_source = $('#tipping-report-template').html();
		var tipping_report_template = Handlebars.compile(tipping_report_source);
		var tipping_report_html = tipping_report_template(stage_info);
		$('#content-with-nav').append(tipping_report_html);
		
		//Tipping report creator
		if (stage_info['allow_tipping_report_creation']) {
			var tipping_report_creator_source = $('#tipping-report-creator-template').html();
			var tipping_report_creator_template = Handlebars.compile(tipping_report_creator_source);
			var tipping_report_creator_html = tipping_report_creator_template({
				'competition_id': competition_id, 
				'stage_id': stage_id,
				'stage_name': stage_info['stage_name'].toUpperCase()
			});
			$('#content-with-nav').append(tipping_report_creator_html);
		}
		
		//Tip sheet
		if (stage_info['remaining']>0) {
			new CountdownTimer('div.countdown', stage_info['remaining']);
			
			var tip_sheet_source   = $('#tip-sheet-template').html();
			var tip_sheet_template = Handlebars.compile(tip_sheet_source);
			var tip_sheet_html = tip_sheet_template({});
			$('#content-with-nav').append(tip_sheet_html);
			
			$.get('/competitions/get_tip_sheet/'+competition_id, {stage_id:stage_id}, function(tip_sheet_info) {
				var tip_sheet_team_source = $('#tip-sheet-team-template').html();
				var tip_sheet_team_template = Handlebars.compile(tip_sheet_team_source);
				$(tip_sheet_info.tipsheet).each(function(ndx, team) {
					var context = {};
					context['team_ndx'] = ndx;
					context['team_name'] = team['team_name'];
					var tip_sheet_team_html = tip_sheet_team_template(context);
					$('div#tip-sheet div.teams').append(tip_sheet_team_html);
					
					var team_elt = $('div.team[ndx='+ndx+']');
					
					var tip_sheet_team_rider_source = $('#tip-sheet-team-rider-template').html();
					var tip_sheet_team_rider_template = Handlebars.compile(tip_sheet_team_rider_source);
					$(team.riders).each(function(ndx2, rider) {
						var context = {}
						context['allowed'] = rider.allowed['allowed'];
						context['rider_name'] = rider['rider_name'];
						context['rider_number'] = rider['rider_number'];
						context['rider_id'] = rider['rider_id'];
						context['reason'] = rider.allowed['reason'];
						context['selected'] = (rider['rider_id']==stage_info['rider_id']);
						context['competition_id'] = competition_id;
						context['stage_id'] = stage_id;
						var tip_sheet_team_rider_html = tip_sheet_team_rider_template(context);
						$(team_elt).append(tip_sheet_team_rider_html);
						
						if (context['selected']) $(team_elt).find('div.rider[rider-id='+rider['rider_id']+']').addClass('selected');
					});
				});
				$('div#tip-sheet div.teams').append('<div style="clear:both;"></div>');
			});
		}
		//Stage leaderboard
		else {
			load_stage_leaderboard(competition_id, stage_info['race_id'], stage_id);
		}
		
		loading_stage_info = false;
		$('#content-with-nav').removeClass('loading-overlay');
	});
}

var stage_leaderboard_type = 'tipping';
var stage_leaderboard_scope = 'stage';
var stage_leaderboard_initialized = false;
var stage_leaderboard_loaded_tables = {'tipping':{}, 'race':{}};
//Title:		load_stage_leaderboard
//Description:	Loads leaderboard into the stage details page
function load_stage_leaderboard(competition_id, race_id, stage_id, type, scope) {
	if (type==stage_leaderboard_type && scope==stage_leaderboard_scope) return;
	
	if (type==null) type = stage_leaderboard_type;
	if (scope==null) scope = stage_leaderboard_scope;
	
	url = '';
	var params = {};
	if (type=='tipping') {
		params['group_type'] = 'stage';
		if (scope=='stage') {
			url = '/competitions/get_competition_leaderboard/'+competition_id;
			params = {'group_type':'stage', 'group_id':stage_id};
		}
		if (scope=='cumulative') {
			url = '/competitions/get_competition_leaderboard/'+competition_id;
			params = {'group_type':'race', 'group_id':race_id};
		}
	}
	if (type=='race') {
		if (scope=='stage') {
			url = '/stages/get_results/'+stage_id;
		}
		if (scope=='cumulative') {
			url = '/races/get_results/'+race_id;
		}
	}
	
	if (url.length==0) return;
	
	if (stage_leaderboard_loaded_tables[type][scope]) {
		$('div#stage-leaderboard tr.entry').hide();
		$('div#stage-leaderboard tr.entry.'+type+'.'+scope).show();
	} else {
		$.get(url, params, function(response) {
			var context = {};
			//Standardize response
			var entries = [];
			if (type=='tipping') {
				$(response.leaderboard).each(function(ndx, entry) {
					entries.push({
						'rank': ndx+1,
						'name': entry['username'],
						'tip': (entry['tip']==null)?null:entry['tip'][0]['name'],
						'time': entry['time_formatted'],
						'sprint': entry['sprint'],
						'kom': entry['kom'],
						'type': type,
						'scope': scope,
					});
				});
				context['entries'] = entries;
				context['competition_id'] = competition_id;
				context['race_id'] = race_id;
				context['stage_id'] = stage_id;
			}
			else if (type=='race') {
				$(response.results).each(function(ndx, entry) {
					entries.push({
						'rank': ndx+1,
						'name': entry['rider_name'],
						'tip': (entry['tip']==null)?null:entry['tip'][0]['name'],
						'time': (entry['disqualified']==null)?entry['time_formatted']:entry['disqualified'],
						'sprint': (entry['disqualified']==null)?entry['sprint_points']:'--',
						'kom': (entry['disqualified']==null)?entry['kom_points']:'--',
						'type': type,
						'scope': scope,
					});
				});
				context['entries'] = entries;
				context['competition_id'] = competition_id;
				context['race_id'] = race_id;
				context['stage_id'] = stage_id;
			}
			
			//Initialize table
			if (!stage_leaderboard_initialized) {
				var stage_leaderboard_source = $('#stage-leaderboard-template').html();
				var stage_leaderboard_template = Handlebars.compile(stage_leaderboard_source);
				var stage_leaderboard_html = stage_leaderboard_template(context);
			
				$('#content-with-nav').append(stage_leaderboard_html);
				
				stage_leaderboard_initialized = true;
				$('div#stage-leaderboard table.data').tablesorter();
			}
			//Add new rows
			else {
				var stage_leaderboard_row_source = $('#stage-leaderboard-row-template').html();
				var stage_leaderboard_row_template = Handlebars.compile(stage_leaderboard_row_source);
				var stage_leaderboard_row_html = stage_leaderboard_row_template(context);
				
				$('div#stage-leaderboard tr.entry').not('.'+type+'.'+scope).hide();
				$('div#stage-leaderboard tbody').append(stage_leaderboard_row_html);
				
				$('div#stage-leaderboard table.data').trigger('update');
			}
			stage_leaderboard_loaded_tables[type][scope] = true;
		});
	}
	
	if (type!=null) stage_leaderboard_type = type;
	if (scope!=null) stage_leaderboard_scope = scope;
	
	//Set scope switch
	$('div#stage-leaderboard th.choice.toggle div.switch.yellow').removeClass('yellow').addClass('gray');
	$('div#stage-leaderboard th.choice.toggle div.switch.'+scope).addClass('yellow').removeClass('gray');
	//Set table type color
	if (type=='tipping') {
		$('div#stage-leaderboard table.data.grayblack').removeClass('grayblack').addClass('blue');
	}
	else if (type=='race') {
		$('div#stage-leaderboard table.data.blue').removeClass('blue').addClass('grayblack');
	}
	
}
//Title:		change_stage_leaderboard
//Description:	Toggle between stage leaderboard types
function change_stage_leaderboard(competition_id, race_id, stage_id, type, value) {
	if (type=='type') {
		load_stage_leaderboard(competition_id, race_id, stage_id, value, stage_leaderboard_scope);
	}
	else if(type=='scope') {
		load_stage_leaderboard(competition_id, race_id, stage_id, stage_leaderboard_type, value);
	}
}

//Title:		load_other_information
//Description:	Loads other information into the competitions screen
function load_other_information(competition_id) {
	var other_info_source = $('#other-information-template').html();
	var other_info_template = Handlebars.compile(other_info_source);
	
	$.get('/competitions/get_competition_other_info/'+competition_id, {}, function(response) {
		console.log(response);
		var other_info_html = other_info_template(response);
		$('#content-with-nav').html(other_info_html);
	});
}

//Title:		save_tie_break_info
//Description:	Save tie break information
function save_tie_break_info(competition_id) {
	var container = $('#other-information');
	
	$(container).find('.tie-break-footer .btn').removeClass('yellow').addClass('gray');
	$(container).find('.tie-break-footer .loading').show();
	$(container).find('.tie-break-footer .success').hide();
	
	var data = {};
	data['rider_id'] = $(container).find('select.tie-break-rider').val();
	data['days'] = $(container).find('div.tie-break-time input[name=days]').val();
	data['hours'] = $(container).find('div.tie-break-time input[name=hours]').val();
	data['minutes'] = $(container).find('div.tie-break-time input[name=minutes]').val();
	data['seconds'] = $(container).find('div.tie-break-time input[name=seconds]').val();
	
	$.post('/competitions/save_tie_break_info/'+competition_id, data, function(response) {
		if (!response.success) {
			alert(response.msg);
		} else {
			$(container).find('.tie-break-footer .success').show();
		}
		
		$(container).find('.tie-break-footer .btn').removeClass('gray').addClass('yellow');
		$(container).find('.tie-break-footer .loading').hide();
	});
}

//Title:		save_user_basic_information
//Description:	Saves basic user information from the user settings page
var saving_user_basic_information = false;
function save_user_basic_information() {
	if (saving_user_basic_information) return;
	
	var container = $('#user-settings div.basic-information');
	
	saving_user_basic_information = true;
	$(container).find('div.btn').removeClass('yellow').addClass('gray');
	$(container).find('div.loading').show();
	$(container).find('div.success').hide();
	
	var data = {'information':{}, 'password':{}};
	data['information']['firstname'] = $(container).find('input[name=firstname]').val();
	data['information']['lastname'] = $(container).find('input[name=lastname]').val();
	data['information']['display_name'] = $(container).find('input[name=display_name]').val();
	data['information']['about_me'] = $(container).find('textarea[name=about_me]').val();
	
	data['password']['old_password'] = $(container).find('input[name=old_password]').val();
	data['password']['new_password'] = $(container).find('input[name=new_password]').val();
	
	$.post('/users/save_information', data, function(response) {
		if (!response.success) {
			alert (response.msg);
		} else {	
			$(container).find('div.success').show();
		}
		saving_user_basic_information = false;
		$(container).find('div.btn').removeClass('gray').addClass('yellow');
		$(container).find('div.loading').hide();
	});
}

//Title:		save_tipping_report
//Description:	Save a tipping report
var saving_tipping_report = false;
function save_tipping_report(competition_id, stage_id, elt) {
	if (saving_tipping_report) return;
	
	var container = $(elt).parent();
	$(elt).removeClass('yellow').addClass('gray');
	$(container).find('div.loading').show();
	saving_tipping_report = true;
	
	var title = $(container).find('input[name=title]').val();
	var report = $(container).find('textarea[name=report]').val();
	
	$.post('/competitions/save_report/'+competition_id, {stage_id:stage_id, title:title, report:report}, function(response) {
		if (response.success) {
			context = {};
			context['report_id'] = response.msg;
			context['stage_name'] = $(container).parent().find('div.title').html().replace('TIPPING REPORT', '');
			context['title'] = title;
			context['report'] = report;
			
			var tipping_report_source = $('#tipping-report-template').html();
			var tipping_report_template = Handlebars.compile(tipping_report_source);
			var tipping_report_html = tipping_report_template({'tipping_reports': [context]});
			
			$('.tipping-report').first().before(tipping_report_html);
			
			$(container).find('input[name=title]').val('');
			$(container).find('textarea[name=report]').val('');
		} else {
			alert(response.msg);
		}
		
		saving_tipping_report = false;
		$(elt).removeClass('gray').addClass('yellow');
		$(container).find('div.loading').hide();	
	});
}

//Title:		delete_report
//Description:	Delete a tipping report
var deleting_tipping_report = false;
function delete_report(report_id, elt) {
	if (deleting_tipping_report) return;
	
	var container = $(elt).parent();
	$(elt).removeClass('yellow').addClass('gray');
	$(container).find('.loading').show();
	
	if (!confirm("Are you sure you want to delete this report?")) return;
	
	$.post('/competitions/delete_report/'+report_id, {}, function(response) {
		if (response.success) {
			$(container).parent().remove();
		} else {
			alert(response.msg);
			$(elt).removeClass('yellow').addClass('gray');
			$(container).find('.loading').show();
		}
	});
}