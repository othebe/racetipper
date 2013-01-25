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
	rider_container = $(elt).closest('.tip_rider');
	rider_id = $(rider_container).attr('rider_id');
	
	tip_container = $('.tip_data');
	competition_id = $(tip_container).attr('competition_id');
	race_id = $(tip_container).attr('race_id');
	stage_id = $(tip_container).attr('stage_id');
	
	$('.tip_rider').removeClass('selected-mask');
	$(rider_container).addClass('selected-mask');

	$.post('/competitions/tip', {rider_id:rider_id, race_id:race_id, competition_id:competition_id, stage_id:stage_id}, function(response) {
		if (!response.success) {
			alert(response.msg);
			$('.tip_rider').removeClass('selected-mask');
		}
	});
	
	event.preventDefault();
}

//Get competition stage data
function get_competition_stage_data(competition_id, stage_id) {
	$('.stage_data_container').addClass('fade');
	$('.tip_rider').removeClass('selected-mask');
	$('.stage_img').attr('src', '/assets/ajax-loader.gif');
	
	$.get('/competitions/get_competition_stage_info.json', {competition_id:competition_id, stage_id:stage_id}, function(response) {
		data = response.data;

		distance_str = data.stage_start_location+' - '+data.stage_end_location+' ('+data.stage_distance_km+' km)';
		$('.stage_img').attr('src', data.stage_image_url);
		$('.description p').html(data.stage_description);
		$('.profile p').html(data.stage_profile);
		$('.starts_on p').html(data.stage_starts_on);
		$('.distance p').html(distance_str);
		$('.time_to_tip p').html(data.time_to_tip);
		$('.tip_data').attr('stage_id', stage_id);
		$('.tip_rider[rider_id='+data.tipped_rider_id+']').addClass('selected-mask');
		
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

$(document).ready(function(event) {
	$("body").bind("ajaxSend", function(elm, xhr, s){
		if (s.type == "POST") {
		  xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
		}
	});
	
	$('.close_fancybox').click(function() {
		$.fancybox.close();
	});
	
	show_season_info();
	show_competitions();
	show_profile();
});