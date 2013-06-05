function share_fb(elt) {
	width = 700;
	height = 300;
	url = encodeURIComponent($(elt).closest('ul.social').attr('url'));
	link = 'https://www.facebook.com/sharer/sharer.php?u='+url;
	open_share_popup(link, 'Share on Facebook', width, height);
}

function share_tw(elt) {
	width = 700;
	height = 300;
	url = encodeURIComponent($(elt).closest('ul.social').attr('url'));
	title = encodeURIComponent($(elt).closest('ul.social').attr('name'));
	link = 'https://twitter.com/intent/tweet?text='+title+'&url='+url;
	open_share_popup(link, 'Share on Twitter', width, height);
}

function share_googlep(elt) {
	width = 700;
	height = 400;
	url = encodeURIComponent($(elt).closest('ul.social').attr('url'));
	link = 'https://plus.google.com/share?url='+url+'&hl=en-US';
	open_share_popup(link, 'Share on Google+', width, height);
}

//Popup for share
function open_share_popup(link, windowName, width, height) {
	if (!window.focus)return true;
	if (typeof(link) == 'string')
	   href=link;
	else href=link.href;
	window.open(href, windowName, 'width='+width+',height='+height+',scrollbars=no');
	return false;
}
