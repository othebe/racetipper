$(document).ready(function(event) {
	
});

//Title:		login
//Description:	Log a user in
function login(elt) {
	var container = $('.signin');
	data = {};
	data['email'] = $(container).find('input[name=email]').val();
	data['password'] = $(container).find('input[name=password]').val();
	
	$(elt).hide();
	load_img = $(container).find('img.loading').show();
	
	$.post('/users/login', {data:data}, function(response) {
		if (response.success) {
			window.location.hash = '#competitions/index';
			window.location.reload();
		} else alert(response.msg);
		$(load_img).hide();
		$(elt).show();
	});
	
	return false;
}

//Title:		logout
//Description:	Log out user
function logout() {
	window.location.href = '/users/logout';
}

//Title:		signup
//Description:	Sign a new user up
function signup(elt) {
	var container = $('.signup');
	data = {};
	data['firstname'] = $(container).find('input[name=firstname]').val();
	data['lastname'] = $(container).find('input[name=lastname]').val();
	data['email'] = $(container).find('input[name=email]').val();
	data['password'] = $(container).find('input[name=password]').val();
	
	$(elt).hide();
	load_img = $(container).find('img.loading').show();
	
	$.post('/users/create', {data:data}, function(response) {
		if (response.success) {
			window.location.hash = '#competitions/index';
			window.location.reload();
		} else alert (response.msg);
		$(load_img).hide();
		$(elt).show();
	});
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
					var click_scr = "load_page('#competitions/show_tips/"+competition_id+"?uid=1')";
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
	});
}

//Title:		show_tip_sheet
//Description:	Show tip sheet for a competition stage
//Params:		elt - Object that triggers a tip sheet load
function show_tip_sheet(elt) {
	var parent = $(elt).parent();
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
		
		$(data_elt).find('input[type=checkbox]').click(function(event) {
			$('input[type=checkbox]').removeAttr('checked');
			$(this).attr('checked', true);
			rider_id = $(this).attr('id');
			save_tip(competition_id, stage_id, rider_id);
		});
		
		$(load_img).hide();
	});
}

//Title:		save_tip
//Description:	Save a tip
function save_tip(competition_id, stage_id, rider_id) {
	//Clear all verification messages
	$('span.selection_verify').html('');
	
	//Loader image
	var loader = $('img.saving_tip_loader.template').clone().removeClass('template');
	
	//Append loader for selection
	var selection = $('span#'+rider_id+'.selection_verify');
	$(selection).html(loader);
	
	$.post('/competitions/save_tip/'+competition_id, {stage_id:stage_id, rider_id:rider_id}, function(response) {
		if (!response.success) 
			alert(response.msg);
		else $(selection).html([' (',response.msg,')'].join(''));
	});
}

//Title:		Join a competition
//Description:	Join a competition
function join_competition(competition_id, elt) {
	$(elt).hide();
	var loader = $(elt).parent().find('div.load_container.competition').show();
	var url = '/competitions/join/'+competition_id
	
	$.post(url, {}, function(response) {
		if (response.success) {
			window.location.hash = '#competitions/tip/'+competition_id;
		} else alert(response.msg);
		
		$(elt).show();
		$(loader).hide();
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
function save_competition() {
	var form = $('#competition_form');
	var data = {};
	data['id'] = $(form).find('#competition_id').val();
	data['competition_name'] = $(form).find('#name').val();
	data['competition_description'] = $(form).find('#description').val();
	data['open_to'] = $(form).find('input[name=open_to]:checked').val();
	data['invitations'] = $(form).find('#invitations').val();
	data['image_name'] = $(form).find('#image_name').val();
	data['races'] = [];
	$(form).find('input[name=race]:checked').each(function(ndx, elt) {
		data['races'].push($(elt).val());
	});
	$.post('/competitions/save_competition', {data:data}, function(response) {
		if (!response.success)
			alert(response.msg);
		else {
			$('#competition_id').val(response.id);
			form = document.getElementById('image_upload');
			form.submit();
		}
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

//Title:		change_password
//Description:	Change password
function change_password(elt) {
	var password = $('input[name=new_password]').val();
	var verify_password = $('input[name=verify_password]').val();
	
	//Passwords dont match
	if (password != verify_password) {
		alert('Your passwords do not match.');
		return false;
	}
	
	$(elt).hide();
	$('img.loading.change_password').show();
	
	$.post('/users/change_password', {password:password}, function(response) {
		alert(response.msg);
			
		$(elt).show();
		$('img.loading.change_password').hide();
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

//Title:		load_comments
//Description:	Loads Facebook comments and fixes scrollbars
function load_comments() {
	$('.fb-comments').attr('data-width', document.width * 0.6);
	FB.XFBML.parse();
	moduleTextPage(true);
}