var script = document.createElement('script');
script.src = 'http://code.jquery.com/jquery-latest.min.js';

var head = document.getElementsByTagName('head')[0];
var done = false;

script.onload = script.onreadystatechange = function() {
    if ( ! done && ( ! this.readyState
                    || this.readyState == 'loaded'
                    || this.readyState == 'complete') ) {
        done = true;
        
        // We'll check this every now and then
        document.IMWebViewJqueryLoaded = true;
        $imWebViewJquery = jQuery.noConflict();
        
        script.onload = script.onreadystatechange = null;
        head.removeChild(script);
    }
};

head.appendChild(script);