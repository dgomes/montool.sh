
var pachube = {
	apiKey: null,
	feed: null,
	datastream: new Object(), 
	requestDatastream: function(datastream, duration) {
		data = this.datastream;
		now = new Date();
		nowstr = now.getFullYear()+"-"+(now.getMonth()+1)+"-"+now.getDate()+"T"+now.getHours()+":"+now.getMinutes()+":00";
		url = 'http://api.pachube.com/v2/feeds/'+this.feed+'/datastreams/'+datastream+'.json?end='+nowstr+'&duration='+duration+'&per_page=1000&interval_type=discrete&find_previous&interval_type=discrete';
		new Ajax.Request( url, { method:'get',
			requestHeaders: ['X-PachubeApiKey', this.apiKey],
		    onSuccess: function(transport){
			    data[datastream] = transport.responseJSON;
		    },
		    onFailure: function(){ alert('Failed to load datastream from Pachube') }
		});
	},
	convert: function(data) {
			 if(data == null) return null;
			 var c = Array();
			 data.datapoints.each(function(item, i) { 
				 var point = [i, item.value];
				 c.push(point);
			 })
			 return c;
		 },
	energyToEuros: function(data, t) {
			       if(data == null) return null;
			       var e = Array();
			       data.datapoints.each(function(item, i) {
				       time = new Date(item.at);
				       var cost = t(time);
				       var point = [i, Math.round(item.value*cost/10)/100];
				       e.push(point);
			       })
			       return e;
		       }
}
