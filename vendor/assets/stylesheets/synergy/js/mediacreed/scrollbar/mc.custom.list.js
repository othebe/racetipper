/* mediacreed custom scrollbar plugin - http://www.mediacreed.com */

(function( $ ) {

    var m = Math,
	dummyStyle = document.createElement('div').style,
	vendor = (function () {
		var vendors = 't,webkitT,MozT,msT,OT'.split(','),
			t,
			i = 0,
			l = vendors.length;

		for ( ; i < l; i++ ) {
			t = vendors[i] + 'ransform';
			if ( t in dummyStyle ) {
				return vendors[i].substr(0, vendors[i].length - 1);
			}
		}

		return false;
	})(),
	cssVendor = vendor ? '-' + vendor.toLowerCase() + '-' : '',

	// Style properties
	transform = prefixStyle('transform'),
	transitionProperty = prefixStyle('transitionProperty'),
	transitionDuration = prefixStyle('transitionDuration'),
	transformOrigin = prefixStyle('transformOrigin'),
	transitionTimingFunction = prefixStyle('transitionTimingFunction'),
	transitionDelay = prefixStyle('transitionDelay'),

    // Browser capabilities
	isAndroid = (/android/gi).test(navigator.appVersion),
	isIDevice = (/iphone|ipad/gi).test(navigator.appVersion),
	isTouchPad = (/hp-tablet/gi).test(navigator.appVersion),

    has3d = prefixStyle('perspective') in dummyStyle,
    hasTouch = 'ontouchstart' in window && !isTouchPad,
    hasTransform = vendor !== false,
    hasTransitionEnd = prefixStyle('transition') in dummyStyle,
    // Helpers
	translateZ = has3d ? ' translateZ(0)' : '';


    $.fn.McCustomList = function( options ) {
        if( options == null )
            console.log('NO OPTIONS PROVIDED for ' + $(this).attr("id") );
            
        var id                      = $(this).attr("id");
        var $scrollDirection        = getOptionValue( options.scrollDirection );    /* horizontal or vertical */
        var $scrollType             = getOptionValue( options.scrollType );         /* scroll type: 'linear' or 'oneByOne' */
        var $mainContainer          = $("#" + id );                                 /* container that holds the list */
        var isTouchDevice           = getOptionValue( options.isTouchDevice );       
               
        /*properties to be set on init*/
        var $scrollContainer        = null; 
        var $mouseWheelSupport      = null;
        var $buttonsSupport         = null;
        var $draggerContainer       = null;
        var $draggerScroll          = null;
        var $totalMinusSize         = null; /* When using 100% on lists usually it takes the entire screenX or Y resolution.
                                               If our list is positioned with a left margin of 200px than from mainContainer 100% we have to
                                               take away 200px so we have the correct size( width/height ) */   
        var $scrollSpeed            = null;
        var $offsetSize             = null; 
        var $horizFixHolder         = null;
        var $customStartPosition    = null;
        
        var $linearScrollValue      = 0;
        var $draggerScrollLimit     = 0; /*used when scrollType is "linear"*/ 
        var $maxScrollingValue   	= 0;
        var $lastScrollingValue  	= 0;
	    var $indexMaxVal			= 0;
        var $indexVal				= 0;
        var $currentScrollPosition  = 0;
        var $draggerAutoHeight      = true;
        var $draggerHeightRatio     = 1;
        /*setup list*/
        this.setupList = function( values )
        {
            $scrollContainer        = ( values.scrollContainer == undefined || null ) ? null : values.scrollContainer;       
            $mouseWheelSupport      = ( values.mouseWheelSupport == undefined || null ) ? null : values.mouseWheelSupport;  
            $buttonsSupport         = ( values.buttonsSupport == undefined || null ) ? null : values.buttonsSupport;        
            $draggerContainer       = ( values.draggerContainer == undefined || null ) ? null : values.draggerContainer;    
            $draggerScroll          = ( values.draggerScroll == undefined || null ) ? null : values.draggerScroll;          
            $totalMinusSize         = ( values.totalMinusSize == undefined || null ) ? null : values.totalMinusSize;        
            $scrollSpeed            = ( values.scrollSpeed == undefined || null ) ? null : values.scrollSpeed;              
            $offsetSize             = ( values.offsetSize == undefined || null ) ? null : values.offsetSize;                
            $horizFixHolder         = ( values.horizFixHolder == undefined || null ) ? null : values.horizFixHolder;          
            $customStartPosition    = ( values.customStartPos == undefined || null ) ? null : values.customStartPos;        
                        
            $offsetSize = parseInt($scrollContainer.css("margin-top")) + parseInt($scrollContainer.css("margin-bottom"));
            initList();                      
        }
        
        this.destroy = function ( resetPosition )
        {       
            if( touchDevice == 1 ){
                disableTouchListeners();
            } 
            if( $scrollContainer != null )
            {
                if( $mouseWheelSupport == "yes" )
                    $("body").unbind("mousewheel");
                if( $scrollDirection == "horizontal"){
                    $scrollContainer.css( "left", $currentScrollPosition + "px" );
                    if( $draggerScroll != null )$draggerScroll.css( "left", 0 + "px" );
                }    
                else {
                    if( resetPosition != false ){
                        $scrollContainer.css( "top", /*$currentScrollPosition +*/ "0px" );
                        if( $draggerScroll != null )$draggerScroll.css( "top", 0 + "px" );
                    }
                    
                }   
                      
                $scrollContainer        = null; 
                $mouseWheelSupport      = null;
                $buttonsSupport         = null;
                $draggerContainer       = null;
                $draggerScroll          = null;
                $totalMinusSize         = null;
                $scrollSpeed            = null;
                $offsetSize             = null;
                $horizFixHolder         = null;  
                /*console.log("DESTROY LIST CALLED");*/
            }    
            //mobileConsole("DESTROY CALLED", $scrollContainer, false);         
        }
        this.disableList = function()
        {
            if( $mouseWheelSupport == "yes" )
                $("body").unbind("mousewheel");
            if( touchDevice == 1 ){
                disableTouchListeners();
            }    
        }
        this.enableList = function()
        {
            if( $mouseWheelSupport == "yes" )
                mouseWheel();
            if( isTouchDevice == 1 ){
              disableTouchListeners(); 
              enableTouchListeners();
            }    
        }
        this.collectGarbage = function ()
        {
            $.fn.McCustomList = null;
        }
        this.updateCustomList = function ( totalMinusSize )
        {
           if( totalMinusSize != undefined && totalMinusSize != null )
                $totalMinusSize = totalMinusSize;
           updateValues();
        }
        this.currentPosition = function()
        {
            return $linearScrollValue;
        }
        this.updateCurrPos = function( value )
        {
            $customStartPosition    = value; 
        }
        this.resetPosition = function( value )
        {
            $linearScrollValue = value;
            var draggerY	= ($linearScrollValue/$maxScrollingValue) * $draggerScrollLimit;
            $scrollContainer.css("top",$linearScrollValue + "px");
            $draggerScroll.css("top",$linearScrollValue + "px");
        }
        this.listAutoScroll = function ( value )
        {
            if( $mouseWheelSupport == "yes" )
                mouseWheelScrollH( value )
        }
        function updateValues()
        {
           if( $scrollContainer == null )return;
           if( $scrollDirection == "horizontal" )
           {
    		   $horizFixHolder.css( "width", 999999 );		   
               $maxScrollingValue = ($scrollContainer.width() + $offsetSize ) - ($mainContainer.width() - $totalMinusSize);    		   
    		   $scrollContainer.css("width",  $scrollContainer.width() );
    		   $horizFixHolder.css("width", '');
               
               $currentScrollPosition = $scrollContainer.position().left;
           }
           else if( $scrollDirection == "vertical")
           {
                $maxScrollingValue = ($scrollContainer.height() + $offsetSize) - ( $mainContainer.height() - $totalMinusSize );
                $draggerHeightRatio = ( $mainContainer.height() - $totalMinusSize ) / ($scrollContainer.height() + $offsetSize);
                
                if( $scrollContainer.position() != null )$currentScrollPosition = $scrollContainer.position().top;  
                
           }
           
            $indexMaxVal = Math.round( $maxScrollingValue / $scrollSpeed ) + 1;
            
            
           if( $maxScrollingValue > 0 )
           {
                if( $draggerContainer != null )
    	   		{
        	   		  if( $draggerContainer.length > 0 )
                      {
                           if( draggerSet == true )
                                $draggerContainer.draggable( "destroy" );
                           setupDragger();  
                           if( $customStartPosition != null && $customStartPosition != undefined )
                                $draggerScroll.css("top", "0px");
                           else
                                TweenMax.to( $draggerScroll, .4, { css:{top: ('0px')}, ease: Cubic.easeOut });     
                      }
    			}		
           }           
           if( $customStartPosition != null && $customStartPosition != undefined )
           {
                $linearScrollValue = Math.abs($customStartPosition);
                var draggerY	= ($linearScrollValue/$maxScrollingValue) * $draggerScrollLimit;
                $scrollContainer.css("top", -$linearScrollValue + "px");
                $draggerScroll.css("top", draggerY + "px");
                
                $customStartPosition = null;
           }
           else
           {
                if( isTouchDevice == 1 ){
                    var scrollID = $scrollContainer.attr("id");
                    scrollElem = document.getElementById(scrollID);
                    startY = 0;
                    moveY = 0; 
                    endY = 0; 
                    currY = 0;
                    _posElement(0);
                } else {
                    TweenMax.to( $scrollContainer, 1, { css:{top: ('0px')}, ease:Sine.easeOut });	  
                }								
                $indexVal = 0;
                $linearScrollValue = 0;
           }	
        }
        var scrollElem = "",
            startTime,
            startY = 0, moveY = 0, endY = 0, currY = 0,
            speedY = 0,
            inertia = true,
            scale = 1,
            useTransform = true,
            useTransition = false
            inertiaInterval = "",
            touchStartPrevent = "";
        function initList()
        {
           if( isTouchDevice == 1 ){
              disableTouchListeners(); 
           }
           updateValues();
           if( $maxScrollingValue > 0 )
           {
            if( $draggerContainer != null )
	   		  if( $draggerContainer.length > 0 )
					setupDragger();
           }
           else
           {
                if( $draggerContainer != null )
	   		      if( $draggerContainer.length > 0 )  
                     $draggerContainer.css("display", "none" );          
           }        
           if( $mouseWheelSupport == "yes" )
	   		  mouseWheel(); 
           
           if( isTouchDevice == 1 ){
               var scrollID = $scrollContainer.attr("id");
               scrollElem = document.getElementById(scrollID);
               /* SET DEFAULT STYLES */ 
               // Normalize options
               
        	   useTransform = hasTransform && useTransform;
        	   useTransition = hasTransitionEnd && useTransition;        
        		// Helpers FIX ANDROID BUG!
        		// translate3d and scale doesn't work together!
        		// Ignoring 3d ONLY WHEN YOU SET that.options.zoom
      		    if ( isAndroid ){
        			translateZ = '';
        		}
               
               scrollElem.style[transitionProperty] =  useTransform ? cssVendor + 'transform' : 'top left';
    		   scrollElem.style[transitionDuration] = '0';
    	       scrollElem.style[transformOrigin] = '0 0';/*linear; cubic-bezier;*/
    		   if (useTransition){
    		      scrollElem.style[transitionTimingFunction] = 'cubic-bezier(0.33,0.66,0.66,1)';
    		   }               
               enableTouchListeners();          
           }             
        }        
        function enableTouchListeners( bubble ){
            (scrollElem).addEventListener( "touchstart", _touchStart, !!bubble);
        }
        function _bindListener(evt, elem, method, bubble){
            (elem || scrollElem).addEventListener( evt, method, !!bubble);
        }
        function _unbindListener(evt, elem, method, bubble){
            (elem || scrollElem).removeEventListener( evt, method, !!bubble);
        }
        function disableTouchListeners( bubble ){
            if( inertiaInterval != "" ){
               clearInterval( inertiaInterval ); 
            }
            if( scrollElem != ""){
                (scrollElem).removeEventListener( "touchstart", _touchStart, !!bubble);    
            }            
            window.removeEventListener( "touchcancel", _touchCancel, !!bubble);
            window.removeEventListener( "touchmove", _touchMove, !!bubble);
            window.removeEventListener( "touchend", _touchEnd, !!bubble);
        }
        
        function _touchStart( evt ){
            touchStartPrevent = evt;
            if( inertiaInterval != "" ){
               clearInterval( inertiaInterval ); 
            }            
            startY = evt.touches[0].pageY;
            moveY = startY;
            currY = endY;          
            startTime = evt.timeStamp || Date.now();
            
            _bindListener("touchcancel", window, _touchCancel);
            _bindListener("touchmove", window, _touchMove);
            _bindListener("touchend", window, _touchEnd);        
        }
        function _touchMove( evt ){
            if(touchStartPrevent != ""){
                touchStartPrevent.preventDefault();
                touchStartPrevent = "";
            }
            moveY = evt.touches[0].pageY;          
            var deltaY = moveY - startY,
    			newY = currY + deltaY,
    			c1, c2, scale,
    			timestamp = evt.timeStamp || Date.now();                
            if( newY > 0 ){
                newY = 0;
            }
            if( Math.abs(newY) >= $maxScrollingValue ){
                newY = -$maxScrollingValue;
            }           
            endY = newY;
            speedY = (deltaY > 0 ) ? -Math.abs(deltaY) : Math.abs(deltaY);
            _posElement( newY );
            if (timestamp - startTime > 300) {
    			//startTime = timestamp;
    		}
        }
        function _touchCancel( evt ){
            _touchEnd( evt );    
        }
        function _touchEnd( evt ){
            if(touchStartPrevent != ""){
                touchStartPrevent.preventDefault();
                touchStartPrevent = "";
            }  
           //changedTouches[0]
            var duration = (event.timeStamp || Date.now()) - startTime;
            if( inertiaInterval != "" ){
               clearInterval( inertiaInterval ); 
            }
            if( duration < 300 ){
                clearInterval( inertiaInterval );
                inertiaInterval = setInterval(function(){            
                    applyInertia();          
               }, 30);  
            }
            _unbindListener("touchcancel", window, _touchCancel);
            _unbindListener("touchmove", window, _touchMove);
            _unbindListener("touchend", window, _touchEnd);
            
        }
        function applyInertia(){
            speedY *= 0.85;
            speedY = speedY;
            if( Math.abs(speedY) < 0.5 ){ speedY = 0; }
            var newY = endY - speedY;
            
            if( newY > 0 ){
                newY = 0;
            }
            if( Math.abs(newY) >= $maxScrollingValue ){
                newY = -$maxScrollingValue;
            }
            endY = Math.round(newY);            
            _posElement( newY );
            if( speedY == 0 && inertiaInterval != "" ){
                clearInterval( inertiaInterval );
            }
        }
        function _posElement( y, time, easeFunc ){            
            if (useTransform && time == undefined) {
                scrollElem.style[transform] = 'translate(' + 0 + 'px,' + y + 'px) scale(' + scale + ')' + translateZ;
    		} else {
    			y = Math.round(y);                      
                scrollElem.style.top = y + 'px';
    		}
            if( $draggerContainer != null )
				if( $draggerContainer.length > 0 )
				{
				   $linearScrollValue = Math.abs(y); 
			       var draggerY	= ($linearScrollValue/$maxScrollingValue) * $draggerScrollLimit;
                   TweenMax.to( $draggerScroll, .6, { css:{top: (draggerY+'px')}, ease: Cubic.easeOut });    
                }
        }
        var draggerSet = false;
        function setupDragger()
        {
            draggerSet = true;
            $draggerContainer.css("display", "inline" );
            			
			if( $scrollDirection == "horizontal" )
			{
				var draggerNewW = ( $draggerContainer.width() / $indexMaxVal )
				if( $scrollType == "oneByOne" )
				{
				    TweenMax.to( $draggerScroll, .3, { css:{ width: draggerNewW + "px" },  ease:Sine.easeOut });
				}	
				
				$draggerScroll.draggable({ 
					axis: "x", 
					containment: "parent", 
					drag: function(event, ui) {
						scrollContent();
					}, 
					stop: function(event, ui) {
						scrollContentRelease();
					}
				});	
			}
			else if( $scrollDirection == "vertical" )
			{
				var draggerNewH = ( $draggerContainer.height() / $indexMaxVal )
				if( $scrollType == "oneByOne" )
				{
                    TweenMax.to( $draggerScroll, .3, { css:{ height: draggerNewH + "px" },  ease:Sine.easeOut });                    
                }
                else if( $scrollType == "linear")
                {
                    if( isTouchDevice == 1 ){ 
                        if( $(window).width() < 768 ){ $draggerHeightRatio = 0.3; } 
                    }
                    if( $draggerAutoHeight == true && $draggerHeightRatio <= 1){
                        draggerNewH = $draggerContainer.height() * $draggerHeightRatio;
                        TweenMax.to( $draggerScroll, .3, { css:{ height: draggerNewH + "px" },  ease:Sine.easeOut });
                    }
                    $draggerScrollLimit = $draggerContainer.height() - draggerNewH; 
                    
                }
				$draggerScroll.draggable({ 
					axis: "y", 
					containment: "parent", 
					drag: function(event, ui) {
					    if( $scrollType == "linear")
                        {                            
                            if( $draggerScroll.position().top > $draggerScrollLimit )
                            {
                                $draggerScroll.css("top", $draggerScrollLimit + "px");
                            }    
                            if( $draggerScroll.position().top < 0 )
                            {
                                $draggerScroll.css("top", "0px");
                            }    
                        } 
						scrollContent();
					}, 
					stop: function(event, ui) {					  
					   scrollContentRelease();
					}
				});	
			}
        }
        function scrollContent() 
	   {
		   if( $scrollDirection == "horizontal" )
		   {
			   var draggerW				= $draggerScroll.width();
			   var draggerContW 		= $draggerContainer.width();
			   var draggerContVisibleW	= draggerContW - draggerW;
			   var draggerPosY 			= $draggerScroll.position().left;
			  
			   var value 				= - ($maxScrollingValue * ( $draggerScroll.position().left / draggerContVisibleW ));			   
			   TweenMax.to( $scrollContainer, 1, { css:{left: (value+'px')}, delay: 0.1, ease:Quart.easeOut }); 
		   }
		   else if( $scrollDirection == "vertical" )
		   {
			   var draggerH				= $draggerScroll.height();
			   var draggerContH 		= $draggerContainer.height();
			   var draggerContVisibleH	= draggerContH - draggerH;
			   var draggerPosY 			= $draggerScroll.position().top;
			   
			   var value 				= - ($maxScrollingValue * ( $draggerScroll.position().top / draggerContVisibleH ));
			   $scrollContainer.css( "top", value + "px" );
		   }
	   }
	   function scrollContentRelease()
	   {
		   if( $scrollDirection == "horizontal" )
		   {
			   
		   }
		   else if( $scrollDirection == "vertical" )
		   {
		      if( $scrollType == "oneByOne" )
			  {
    			   var draggerH				= $draggerScroll.height();
    			   var draggerContH 		= $draggerContainer.height();
    			   var draggerPosY 			= $draggerScroll.position().top;
    			   var value				= (Math.round( draggerPosY / draggerH) )  * draggerH;
    			   var valueScroll 			= Math.round( value / draggerH) * $scrollSpeed; 
    			   
    			   TweenMax.to( $draggerScroll, .6, { css:{top: (value+'px')}, ease: Cubic.easeOut });
    			   TweenMax.to( $scrollContainer, .6, { css:{top: (-valueScroll+'px')}, ease:Cubic.easeOut }); 
              }
              else
              {
                $linearScrollValue = -($scrollContainer.position().top);
              }
		   }
		     
	   }
       function mouseWheel()
       {
            if( $mouseWheelSupport == "yes")
            {
                if( $scrollDirection == "horizontal" )
                {
                    $("body").unbind("mousewheel");
				    $("body").bind("mousewheel", function(event, delta) 
                    {
                        mouseWheelScrollH( delta );
						return false;
					});
                }
                else if( $scrollDirection == "vertical" )
                {
                    $("body").unbind("mousewheel");
				    $("body").bind("mousewheel", function(event, delta) 
                    {                        
                        mouseWheelScrollV(delta)
						return false;
					});  
                }
            }        
       }
       function mouseWheelScrollV( delta )
       {
            var value = 0;
            if( delta < 0 )
            {
                if( $scrollType == "oneByOne" )
	            {
                    /*scroll content with - */
					if( $indexVal < $indexMaxVal - 1 )
					{
						$indexVal++;
					
						var value 		= $indexVal * $scrollSpeed;	
						TweenMax.to( $scrollContainer, .6, { css:{top: (-value+'px')}, ease:Sine.easeOut });									
						
					   	if( $draggerContainer != null )
							if( $draggerContainer.length > 0 )
							{
								var draggerY	= $draggerScroll.height() * $indexVal;
								TweenMax.to( $draggerScroll, .6, { css:{top: (draggerY+'px')}, ease: Cubic.easeOut });
							}
					}
                 }
                 else if( $scrollType == "linear")
                 {
                    if( $linearScrollValue < $maxScrollingValue )
                    {
                        $linearScrollValue += $scrollSpeed;
                        if( $linearScrollValue > $maxScrollingValue )
                            $linearScrollValue = $maxScrollingValue; 
                        
                        TweenMax.to( $scrollContainer, .6, { css:{top: (-$linearScrollValue+'px')}, ease:Sine.easeOut }); 
                        
                        if( $draggerContainer != null )
							if( $draggerContainer.length > 0 )
							{
						       var draggerY	= ($linearScrollValue/$maxScrollingValue) * $draggerScrollLimit;
                               TweenMax.to( $draggerScroll, .6, { css:{top: (draggerY+'px')}, ease: Cubic.easeOut });    
                            }
                    }
                 }        
            }
            else if( delta > 0 )
            {
                if( $scrollType == "oneByOne" )
	            {
                    /*scroll content with + */							
					if( $indexVal > 0 )
					{
						$indexVal--;
					
						var value = $indexVal * $scrollSpeed;								
						TweenMax.to( $scrollContainer, .6, { css:{top: (-value+'px')}, ease:Sine.easeOut });	
						
						if( $draggerContainer != null )
							if( $draggerContainer.length > 0 )
							{							
								var draggerY	= $draggerScroll.height() * $indexVal;
								TweenMax.to( $draggerScroll, .6, { css:{top: (draggerY+'px')}, ease: Cubic.easeOut });
							}
					}
                }
                else if( $scrollType == "linear")
                {
                    if( $linearScrollValue > 0 )
                    {
                        $linearScrollValue -= $scrollSpeed;
                        if( $linearScrollValue < 0 )
                            $linearScrollValue = 0; 
                        
                        TweenMax.to( $scrollContainer, .6, { css:{top: (-$linearScrollValue+'px')}, ease:Sine.easeOut }); 
                        
                        if( $draggerContainer != null )
							if( $draggerContainer.length > 0 )
							{
						       var draggerY	= ($linearScrollValue/$maxScrollingValue) * $draggerScrollLimit;
                               TweenMax.to( $draggerScroll, .6, { css:{top: (draggerY+'px')}, ease: Cubic.easeOut });    
                            }
                    }
                }							
            }
       }
       
       function mouseWheelScrollH( delta )
       {            
            var value = 0;
            if( delta < 0 )
            {
                /*scroll content with - */
				if( $lastScrollingValue == -$maxScrollingValue ) 
                    return;
					
                value = Math.abs( $scrollContainer.position().left - $scrollSpeed )
                if( value > $maxScrollingValue)
                    value = $maxScrollingValue;								
                if( $lastScrollingValue < $maxScrollingValue )
                 {
                    $lastScrollingValue = -value;
                    TweenMax.to( $scrollContainer, .6, { css:{left: (-value+'px')}, ease:Sine.easeOut });
					
					if( $draggerContainer != null )
						if( $draggerContainer.length > 0 )
						{
							var draggerW			= $draggerScroll.width();
							var draggerContW 		= $draggerContainer.width();
							var draggerContVisibleW	= draggerContW - draggerW;
							var draggerY			= Math.abs(draggerContVisibleW * ( value / $maxScrollingValue ));
															
							TweenMax.to( $draggerScroll, .6, { css:{left: (draggerY+'px')}, ease: Cubic.easeOut });
						}
                 }   
            }
            else if( delta > 0 )
            {
                /* scroll content with + */
                if( $lastScrollingValue == 0 )
                    return;
                value = $scrollContainer.position().left + $scrollSpeed;
                if( value > 0)
                    value = 0;
                if( $lastScrollingValue < 0 )
                {
                     $lastScrollingValue = value;
                     TweenMax.to( $scrollContainer, .6, { css:{left: (value+'px')}, ease:Sine.easeOut });
					
					if( $draggerContainer != null )
						if( $draggerContainer.length > 0 )
						{	 
							var draggerW			= $draggerScroll.width();
							var draggerContW 		= $draggerContainer.width();
							var draggerContVisibleW	= draggerContW - draggerW;
							var draggerY			= Math.abs(draggerContVisibleW * ( value / $maxScrollingValue ));
															
							TweenMax.to( $draggerScroll, .6, { css:{left: (draggerY+'px')}, ease: Cubic.easeOut });
						}
                }     
            }  
       }
        /* private method get option value */
        function getOptionValue( option )
        {
            var optionValue = ( option == undefined || null ) ? null : option;            
            return optionValue;
        }
        
        /*THIS IS VERY IMPORTANT TO KEEP AT THE END*/
        return this;
    };

function prefixStyle (style) {
	if ( vendor === '' ) return style;

	style = style.charAt(0).toUpperCase() + style.substr(1);
	return vendor + style;
}

dummyStyle = null;	// for the sake of it

})( jQuery );
