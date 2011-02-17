function searchModalBox () {
   $.fancybox({
     'modal'             : true,
     'content'           : '<div id="searchFancy">' + $("#search").html() + '</div>',
     'titlePosition'     : 'inside',
   	 'titleFormat'       : function(title) {
 		    return '<a id="closeFancyBox" href="#" onclick="$.fancybox.close(); return false;">Cancel</a>';
 		},
 		'onComplete': function() {
       $("input#query").autocomplete({source: '/autocomplete'});
 		}
   });         
   
   $("#query").focus().val('');        
   
   return false;          
}    

function menuModalBox () {
   $.fancybox({
     'modal'             : true,
     'content'           : '<div id="menuFancy">' + $("#menu").html() + '</div>',
     'titlePosition'     : 'inside',
   	 'titleFormat'       : function(title) {
 		    return '<a id="closeFancyBox" href="#" onclick="$.fancybox.close(); return false;">Cancel</a>';
 			}
   });         
      
   return false;          
}

function vlcControlsModalBox () {
   $.fancybox({
     'modal'             : true,
     'content'           : '<div id="vlcControlsFancy">' + $("#vlcControls").html() + '</div>',
     'titlePosition'     : 'inside',
   	 'titleFormat'       : function(title) {
 		    return '<a id="closeFancyBox" href="#" onclick="$.fancybox.close(); return false;">Cancel</a>';
 			}
   });         
      
   return false;          
}

function getPath () {
	var nurl = window.location.toString();;	
	return nurl.split("?")[0];
}

function getPage () {
	var nurl = window.location.toString();;	
	parts = nurl.split("?");
	
	var page = '1';
	
	if (parts[1]) {
		var nparams = parts[1].split("&");
		
		$.each(nparams, function (index, value) {
			var nparam = value.split("=")[0];
			var nvalue = value.split("=")[1];		
			if (nparam == "page") {page=nvalue};
		});		
	};
	
	return parseInt(page);
}

function nextPage () {
	var path = getPath();	
	var page = getPage() + 1;
	var nurl = path + '?page=' + page;
	
	window.location = nurl;		
	return false;
}

function prevPage () {
	var path = getPath();
	var page = getPage() - 1;
	var purl = path + '?page=' + page;
	
	if (page != 0) {
		window.location = purl;		
	};
	
	return false;
}

function upLevel () {
	var nurl = window.location.toString();;	
	
	var path = getPath();
	
	window.location = path.replace(/(search)?\/\d+(\-.*)?/g, "");
}

function ratingUI (netflix_id) {
	
}

function initializeRatingUI (netflix_id) {
	$('.star').rating({
    callback: function(value, link){      
      $.post('/ratings', { rating: value, netflix_id: netflix_id });
   }});
}

function updateRatingForFilm (netflix_id) {
	$.get('/ratings/' + netflix_id + '', function (data) {
		$('input').rating('select', data.rating);
	})
}