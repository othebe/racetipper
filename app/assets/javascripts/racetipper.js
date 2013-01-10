//Show competition section
competitions_loaded = false;
function show_competitions() {
	var container = $('.competition_portfolio');
	if (competitions_loaded) return;
	$.get('/dashboard/show_competitions', {}, function(response) {
		$(container).html(response);
		$(container).height('auto');
		competitions_loaded = true;
	});
}

//Show season info section
season_info_loaded = false;
function show_season_info() {
	var container = $('.season_info_portfolio');
	if (season_info_loaded) return;
	$.get('/dashboard/show_season_info', {}, function(response) {
		$(container).html(response);
		$(container).height('auto');
		season_info_loaded = true;
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
	
	$.get('/competitions/get_competition_stage_info.json', {competition_id:competition_id, stage_id:stage_id}, function(response) {
		data = response.data;

		distance_str = data.stage_start_location+' - '+data.stage_end_location+' ('+data.stage_distance_km+' km)';
		$('.stage_img').attr('src', data.stage_image_url);
		$('.description p').html(data.stage_description);
		$('.profile p').html(data.stage_profile);
		$('.starts_on p').html(data.stage_starts_on);
		$('.distance p').html(distance_str);
		$('.tip_data').attr('stage_id', stage_id);
		$('.tip_rider[rider_id='+data.tipped_rider_id+']').addClass('selected-mask');
		
		$('.stage_data_container').removeClass('fade');
	});
}

function init_slider() {
	console.log('init');
	$('.bxslider').bxSlider({
		minSlides: 7,
		maxSlides: 7,
		slideMargin: 10
	});
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
});