/* Velotipper iframe object */

var VelotipperIframeBuddy = function(elt_id) {
	this.SITE_URL = 'http://racetipper.herokuapp.com/';
	this.MSG_TYPES = ['RESIZE'];
	this.SEPARATOR = '^';
	
	this.iframe_elt = document.getElementById(elt_id);
	this.parent_params = this.parse_parent_params();
	this.iframe_params = this.parse_iframe_params();
	
	this.init_listeners();
	
	if (this.parent_params['competition_id'] != null) {
		this.show_competition();
	}
}

//Event listeners
VelotipperIframeBuddy.prototype.init_listeners = function() {
	var orig = this;
	window.addEventListener('message', function(event) {
		var data = event.data.split(orig.SEPARATOR);

		if (orig.MSG_TYPES[data[0]] == 'RESIZE') {
			console.log(data);
			setTimeout(function() {
				orig.iframe_elt.style.height = data[1]+'px';
			}, 700);
		}
	});
};

//Parse parent window params
VelotipperIframeBuddy.prototype.parse_parent_params = function() {
	var params = {};
	var qry_ndx = window.location.href.indexOf('?');
	
	if (qry_ndx > -1) params = parseQuery(window.location.href.substr(qry_ndx+1));
	
	return params;
}

//Parse parent window params
VelotipperIframeBuddy.prototype.parse_iframe_params = function() {
	var params = {};
	var qry_ndx = this.iframe_elt.getAttribute('src').indexOf('?');
	
	if (qry_ndx > -1) params = parseQuery(this.iframe_elt.getAttribute('src').substr(qry_ndx+1));
	
	return params;
}

//Show competition in iframe
VelotipperIframeBuddy.prototype.show_competition = function() {
	src = ['?code='+this.parent_params['code'], 'pid='+this.iframe_params['pid'], 'email='+this.iframe_params['email'], 'key='+this.iframe_params['key'], 'display='+this.iframe_params['display']].join('&');
	
	src = this.SITE_URL+'competitions/'+this.parent_params['competition_id']+src;
	this.iframe_elt.src = src;
}

/******** parses query into key-value parameters ********/
function parseQuery ( query ) {
   var Params = new Object ();
   if ( ! query ) return Params; // return empty object
   var Pairs = query.split(/[;&]/);
   for ( var i = 0; i < Pairs.length; i++ ) {
          var KeyVal = Pairs[i].split('=');
          if ( ! KeyVal || KeyVal.length != 2 ) continue;
          var key = unescape( KeyVal[0] );
          var val = unescape( KeyVal[1] );
          val = val.replace(/\+/g, ' ');
          Params[key] = val;
   }
   return Params;
}

//location.href='/competitions/55?pid=cyclingtips&email=othebe@gmail.com&key=42b4654e512040d617c9d921154f15eb155dc2b2&display=cyclingtips'
//http://localhost/cyclingtips/index.htm?competition_id=55&code=IrnRjMOYfu