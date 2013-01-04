competitions_loaded = false;
function show_competitions() {
	var container = $('#portfolio-items');
	if (competitions_loaded) return;
	$.get('/dashboard/show_competitions', {}, function(response) {
		$(container).html(response);
		$(container).height('auto');
		competitions_loaded = true;
	});
}

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

function hide_new_competition() {
	$('#new_competition').hide();
	$('#portfolio-items').show();
	$('#competitions .caption').show();
	$('#filters .hide_new_competition').hide();
	$('#filters').find('li').not('.hide_new_competition').show();
	$('#portfolio-items').height('auto');
	$(".iscroll-wrapper").jScroll('refresh');
}

function join_competition(competition_id, event) {
	$.post('/competitions/join', {competition_id:competition_id}, function(response) {
		if (response.success) {
			$('.race_results').fadeIn();
		}
	});
	event.preventDefault();
}

$(document).ready(function() {
	$("body").bind("ajaxSend", function(elm, xhr, s){
		if (s.type == "POST") {
		  xhr.setRequestHeader('X-CSRF-Token', $('meta[name="csrf-token"]').attr('content'));
		}
	});
});