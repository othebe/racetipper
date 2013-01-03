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
		$(container).fadeIn();
		$(".iscroll-wrapper").jScroll('refresh');
	});
}