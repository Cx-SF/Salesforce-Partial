({
	doInit: function (cmp, evt, hlp) {
		hlp.getAll(cmp, evt);
	},
	doSubscribe: function (cmp, evt, hlp) {
		hlp.sub(cmp, evt);
	},
	doUnsubscribe: function (cmp, evt, hlp) {
		hlp.unsub(cmp, evt);
	},
	doSpecialSubscribe: function (cmp, evt, hlp) {
		var baseURL = cmp.get('v.communityBaseURL');
		var art = cmp.get('v.article');
		var artUrl = baseURL + 'article/' + art.UrlName;
		var redirectUrl = baseURL + 'login/?startURL=' + artUrl + '--a1--';
		console.log('redirectUrl: ' + redirectUrl);
		window.location.href = baseURL + 'login/?startURL=' + artUrl;
	}
})