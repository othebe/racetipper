//Show competition section
competitions_loaded = false;
function show_competitions() {
	var container = $('.competition_portfolio');
	if ($('.competition_portfolio').length==0) return;
	if (competitions_loaded) return;
	$.get('/dashboard/show_competitions', {}, function(response) {
		$(container).html(response);
		$(container).isotope('reloadItems');
		$(container).height('auto');
		$('#filters li.current a').click();
		setupPortfolio();
		init_page();
		competitions_loaded = true;
	});
}

//Show season info section
season_info_loaded = false;
function show_season_info() {
	var container = $('.season_info_portfolio');
	if ($('.season_info_portfolio').length==0) return;
	if (season_info_loaded) return;
	$.get('/dashboard/show_season_info', {}, function(response) {
		$(container).html(response);
		$(container).height('auto');
		setupPortfolio();
		init_page();
		season_info_loaded = true;
	});
}

//Show profile section
profile_loaded = false;
function show_profile() {
	var container = $('.profile_portfolio');
	if ($('.profile_portfolio').length==0) return;
	if ($(container).html().length>0) return;
	if (profile_loaded) return;
	$.get('/dashboard/show_profile', {}, function(response) {
		$(container).html(response);
		$(container).height('auto');
		init_page();
		profile_loaded = true;
	});
}



//Show new competition screen
function new_competition() {
	var container = $('#new_competition');
	$.get('/competitions/edit', {}, function(response) {
		$(container).html(response);
		$('#portfolio-items').hide();
		$('#competitions .caption').hide();
		$('#filters .hide_new_competition').show();
		$('#filters').find('li').not('.hide_new_competition').hide();
		$(container).fadeIn();
		$(".iscroll-wrapper").jScroll('refresh');
	});
}

//Hide new competition screen
function hide_new_competition() {
	$('#new_competition').hide();
	$('#portfolio-items').show();
	$('#competitions .caption').show();
	$('#filters .hide_new_competition').hide();
	$('#filters').find('li').not('.hide_new_competition').show();
	$('#portfolio-items').height('auto');
	$(".iscroll-wrapper").jScroll('refresh');
}

//Join a competition
function join_competition(competition_id, event) {
	$('.join_competition_button').hide();
	$('.join_competition_loading').show();	
	
	$.post('/competitions/join', {competition_id:competition_id}, function(response) {
		$('.join_competition_loading').hide();	
		if (response.success) {
			$('.race_results').fadeIn();
			$('.tip_rider_button').show();
		} else {
			alert(response.msg);
			$('.join_competition_button').show();
		}
	});
	event.preventDefault();
}

//Tip rider
function tip_rider(elt) {
	$('input[type=checkbox]').not(':disabled').removeAttr('checked');
	$(elt).attr('checked', true);
	
	rider_id = $(elt).attr('rider_id');
	tip_container = $('.tip_data');
	competition_id = $(tip_container).attr('competition_id');
	race_id = $(tip_container).attr('race_id');
	stage_id = $(tip_container).attr('stage_id');
	stage_name = $(tip_container).attr('stage_name');
	
	//Remove selected stage info from old container
	container = $('div[selected_stage_id='+stage_id+']');
	$(container).removeAttr('selected_stage_id');
	$(container).find('span.selected_stage').html('');
	
	//Insert selected stage info into new container
	container = $(elt).closest('div');
	$(container).attr('selected_stage_id', stage_id);
	$(container).find('span.selected_stage').html(' ('+stage_name+')');

	$.post('/competitions/tip', {rider_id:rider_id, race_id:race_id, competition_id:competition_id, stage_id:stage_id}, function(response) {
		if (!response.success) {
			alert(response.msg);
		}
	});
}

//Get competition stage data
var sort_competition_id = '';
var sort_stage_id = '';
function get_competition_stage_data(competition_id, stage_id, sort_field, sort_dir) {
	$('.stage_data_container').addClass('fade');
	
	//Hide teams
	$('.raceteam').hide();
	
	//Disable rider selection
	$('input[type=checkbox]:checked').each(function(ndx, elt) {
		$(elt).attr('disabled', true);
		$(elt).attr('checked', false);
		$('label[for='+$(elt).attr('id')+']').addClass('disabled');
	});
	
	$('.stage_img').attr('src', '/assets/ajax-loader.gif');
	
	$.get('/competitions/get_competition_stage_info.json', {competition_id:competition_id, stage_id:stage_id, sort:sort_field, dir:sort_dir}, function(response) {
		data = response.data;

		sort_competition_id = competition_id;
		sort_stage_id = stage_id;
		
		distance_str = data.stage_start_location+' - '+data.stage_end_location+' ('+data.stage_distance_km+' km)';
		$('.stage_img').attr('src', data.stage_image_url);
		$('.description p').html(data.stage_description);
		$('.profile p').html(data.stage_profile);
		$('.starts_on p').html(data.stage_starts_on);
		$('.distance p').html(distance_str);
		$('.time_to_tip p').html(data.time_to_tip);
		$('.tip_data').attr('stage_id', stage_id);
		$('.tip_data').attr('stage_name', data.stage_name);
		
		//Allow this stage selection to be selected
		selected_stage = $('div[selected_stage_id='+stage_id+']');
		$(selected_stage).find('input[type=checkbox]').removeAttr('disabled').attr('checked', true);
		$(selected_stage).find('label').removeClass('disabled');
		$(selected_stage).find('span.selected_stage').removeClass('disabled');
		
		//Hide teams if they're not part of the race
		race_id = data.race_id
		$('.raceteam').not('.'+race_id).hide();
		$('.raceteam.'+race_id).show();
		
		//Show results?
		if (data.stage_results != null) {
			$('.tip-rider').hide();
			$('.stage-results').show();
			if (data.stage_results==null || data.stage_results.length==0)
				$('div.stage-results .empty').show();
			else {
				table = $('div.stage-results table');
				$(table).find('tr.data').remove();
				$('div.stage-results .empty').hide();
				for (ndx in data.stage_results) {
					result = data.stage_results[ndx];
					//Check disqualification status
					if (result['disqualified']!=null) {
						time_formatted = result['disqualified'];
						gap_formatted = result['disqualified'];
						kom_points = result['disqualified'];
						sprint_points = result['disqualified'];
					} else {
						time_formatted = result['time_formatted'];
						gap_formatted = result['gap_formatted'];
						kom_points = result['kom_points'];
						sprint_points = result['sprint_points'];
					}
					
					row = $('<tr class="data"></tr>');
					$(row).append('<td>'+result['rank']+'</td>');
					$(row).append('<td>'+result['rider_name']+'</td>');
					$(row).append('<td>'+time_formatted+'</td>');
					$(row).append('<td>'+gap_formatted+'</td>');
					$(row).append('<td>'+kom_points+'</td>');
					$(row).append('<td>'+sprint_points+'</td>');
					$(table).append(row);
				}
				
				$(".leaderboard_table").trigger("update"); 
			}
		} else {
			$('.stage-results').hide();
			$('.tip-rider').show();
		}
		
		$('.stage_data_container').removeClass('fade');
	});
}

//Load more competitions
//Params:
//	options - Associative array:
//		limit
//		offset
function load_more_competitions() {
	container_selector = '#portfolio-items.competition_portfolio';
	container = $(container_selector);
	limit = 10;
	offset = $(container).find('.item:not(.new_competition)').length;
	
	$('#more_competitions').hide();
	$('#more_competitions_loading').show();
	
	$.get('/competitions/get_more_competitions.json', {limit:limit, offset:offset}, function(response) {
		competition_data = response.competition_data
		$(competition_data).each(function(ndx, data) {
			scaffold = $('.item.competition.template').first().clone().removeClass('template').removeClass('competition');
			if (data.is_participant) $(scaffold).addClass('mine');
			$(scaffold).find('img').attr('src', data.image_url).attr('alt', data.name);
			$(scaffold).find('a').attr('data_id', data.id).attr('href', '#/competitions/show/'+data.id);
			$(scaffold).find('.project-title').html(data.name);
			if (data.is_complete) {
				$(scaffold).find('.completion_status').html('Completed');
			}
			
			container.append($(scaffold).fadeIn());
		});
		$('#more_competitions_loading').hide();
		$('#more_competitions').show();
		$(container).isotope('reloadItems');
		$(container).height('auto');
		$('#filters li.current a').click();
		setupPortfolio();
	});
}

function init_slider() {
	$('.bxslider').bxSlider({
		minSlides: 7,
		maxSlides: 7,
		slideMargin: 10
	});
}

function init_page() {
	//Init fancybox
	$("a.article_gallery").fancybox({
		'transitionIn'		: 'none',
		'transitionOut'		: 'none',
		'titlePosition' 	: 'over',
		'titleFormat'       : function(title, currentArray, currentIndex, currentOpts) {
			return '<span id="fancybox-title-over">Image ' +  (currentIndex + 1) + ' / ' + currentArray.length + ' ' + title + '</span>';
		}
	});
}

//Show login popup
function show_login() {
	$('button#login').click();
}

//Scroll to top
function back_to_top() {
	$(window).scrollTop(0);
}

$(document).ready(function(event) {
	$("body").bind("ajaxSend", function(elm, xhr, s){
		if (s.type == "POST") {
		  xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
		}
	});
	
	$('.close_fancybox').click(function() {
		$.fancybox.close();
	});
	
	//User menu links
	$('tr.choice').click(function() {
		href = $(this).attr('href');
		if ($(this).hasClass('_blank')) {
			window.open(href, '_blank');
		} else window.location.href = href;
	});
	
	//Back to top button
	$(window).scroll(function() {
		if (window.scrollY > 0) 
			$('#back_to_top').fadeIn();
		else $('#back_to_top').fadeOut();
	});
	
	show_season_info();
	show_competitions();
	show_profile();
});