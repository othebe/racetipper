competitions_loaded = false;
function show_competitions() {
	var container = $('#portfolio-items');
	if (competitions_loaded) return;
	$.get('/dashboard/show_competitions', {}, function(response) {
		$(container).html(response);
		competitions_loaded = true;
	});
}