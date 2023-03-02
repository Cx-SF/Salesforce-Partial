({
	doInit: function (cmp, evt, hlp) {
		hlp.loadInitialData(cmp, evt);
	},
	productSelected : function(cmp, evt, hlp){
		var target = evt.target;
		console.log('Product selected: ' + target.title);
		if (hlp.isEmpty(target.title)) return;
		var productMapping = cmp.get('v.productMapping');
		cmp.set('v.selectedProduct', target.title);
		cmp.set('v.selectedProductWrap', productMapping[target.title]);
		hlp.getProductVersions(cmp, evt);
	},
	openDownloadModal : function(cmp, evt, hlp){
		var versionId = evt.getSource().get('v.value');
		console.log('Version to download: ' + versionId);
		var currentVersion = null;
		var loadedProductVersions = cmp.get('v.loadedProductVersions');
		for (var i = 0; i < loadedProductVersions.length; i++){
			if (loadedProductVersions[i].Id == versionId){
				currentVersion = loadedProductVersions[i];
				break;
			}
		}
		var optionalDownloadLinks = new Array();
		let link = {};
		link.label = 'Version Release';
		link.value = currentVersion.Download_URL__c;
		optionalDownloadLinks.push(link);
		if (!hlp.isEmpty(currentVersion.Hotfix_URL__c)){
			let link = {};
			link.label = 'Hotfix (latest)';
			link.value = currentVersion.Hotfix_URL__c;
			optionalDownloadLinks.push(link);
		}
		if (!hlp.isEmpty(currentVersion.Content_Pack__c)){
			let link = {};
			link.label = 'Content Pack (latest)';
			link.value = currentVersion.Content_Pack__c;
			optionalDownloadLinks.push(link);
		}
		cmp.set('v.optionalDownloadLinks', optionalDownloadLinks);
		cmp.set('v.downloadModalOpen', true);
	},
	goToPluginTab : function(cmp, evt, hlp){
		var versionId = evt.getSource().get('v.value');
		console.log('Version to load plugins: ' + versionId);
		hlp.getPlugins(cmp, evt);
	},
	closeModal : function(cmp, evt, hlp){
		cmp.set('v.downloadModalOpen', false);
		cmp.set('v.selectedDownloadLinks', new Array());
		cmp.set('v.currentDLObject', null);
		cmp.set('v.selected_account', null);
	},
	doDownloads : function(cmp, evt, hlp){
		var canDownload = true;
		var target = evt.getSource();
		var val = target.get('v.value');
		var available_accounts = cmp.get('v.available_accounts');
		var selected_account = cmp.get('v.selected_account');
		var isPowerPartner = cmp.get('v.isPowerPartner');
		console.log('val: ' + val);
		var theObj = {};
		var params = val.split(':');
		for (var i = 0; i < params.length; i++){
			var single = params[i].split('=');
			theObj[single[0]] = single[1];
		}

		if (isPowerPartner && !hlp.isEmpty(available_accounts) && Array.isArray(available_accounts) && hlp.isEmpty(selected_account)){
			cmp.set('v.currentDLObject', theObj);
			cmp.set('v.downloadModalOpen', true);
			canDownload = false;
		} else if (!hlp.isEmpty(selected_account)){
			theObj.selected_account = selected_account;
		}

		if (canDownload){
			hlp.getURL(cmp, evt, theObj);
		}
				
	},
	selectAndContinue : function (cmp, evt, hlp){
		var selected_account = cmp.get('v.selected_account');
		var combo = cmp.find('AccountCombo');
		var saveObj = cmp.get('v.currentDLObject');

		if (hlp.isEmpty(selected_account)){
			$A.util.addClass(combo, "error-box");
		} else {
			$A.util.removeClass(combo, "error-box");
			saveObj.selected_account = selected_account;
			hlp.getURL(cmp, evt, saveObj);
			cmp.set('v.downloadModalOpen', false);
			cmp.set('v.selected_account', null);
		}
	},
	backToFirst : function(cmp, evt, hlp){
		cmp.set('v.productSelected', false);
		cmp.set('v.pluginTabsLoaded', false);
		cmp.set('v.selectedProduct', null);
		cmp.set('v.selectedProductWrap', null);
	},
	backToSecond : function(cmp, evt, hlp){
		cmp.set('v.pluginTabsLoaded', false);
	}
})