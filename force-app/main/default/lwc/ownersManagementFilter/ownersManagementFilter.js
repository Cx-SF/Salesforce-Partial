import {LightningElement, api} from 'lwc';
import regionalDirector from '@salesforce/apex/OwnersManagementProcessCtrl.getRegionalDirector';
import AccountOwnerr from '@salesforce/apex/OwnersManagementProcessCtrl.getAccountOwner';
import DataTable from '@salesforce/apex/OwnersManagementProcessCtrl.getDataTable';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OwnersManagementFilter extends LightningElement {
    spinner = false;
	rDOptions;
	rDReadOnly = false;
	rDplace; rDUserRoleId;
	rDValue; aOValue; orgValue; positionValue; bCValue; tValue; aSValue; aOName;
	aOOptions;
	orgAndPositonValue = [];
	billingCountryList;
	tepyList;
	statusList;
    dataTableValue;
	extraFilter = false;
	optionText = 'More Options';
	statusValue;
	statusOptions = [];
    @api progressValue;

	init(){
		regionalDirector()
		.then((data)=>{		
			let allUsersName = [];
			const dataUser = data.userList;
			const dataStatus = data.status;
			const accountOwnerList = data.accountOwnerList;
			const billingCountry = data.BillingCountry;
			const types = data.Type;



			for(let d in dataUser){
				allUsersName.push({label: dataUser[d]['Name'], value: dataUser[d]['Id'], UserRoleId: dataUser[d]['UserRoleId']});
			}
			this.rDOptions = allUsersName;
			for(let i in dataStatus){
				this.statusOptions.push({label: dataStatus[i].label, value: dataStatus[i].value});
			}
			if(accountOwnerList.length > 0 ){
				this.rDValue = {label: dataUser[0]['Name'], value: dataUser[0]['Id'], UserRoleId: dataUser[0]['UserRoleId']};
                this.rDplace = dataUser[0]['Name'];
                this.rDUserRoleId = dataUser[0]['UserRoleId'];
				this.rDReadOnly = true;
				let allAccOwnerName = [];
				for(let d in accountOwnerList){
					allAccOwnerName.push({label:accountOwnerList[d]['Name'], value: accountOwnerList[d]['Id']});
					this.orgAndPositonValue.push({Id:accountOwnerList[d]['Id'], org:accountOwnerList[d]['Org_Sub_Region__c'], position:accountOwnerList[d]['Position_ID__c']});
				}
				this.aOOptions = allAccOwnerName;
			}else{
				this.rDplace = 'Select User';
			}

			let allCountry = billingCountry.map(data => { return {label:data['BillingCountry'], value:data['BillingCountry']}}).filter(data => data['value'] !== undefined);
			let allType = types.map(data => { return {label:data.label, value:data.value}}).filter(data => data.value !== undefined);
			let allStatus = [{label:'Prospect', value:'Prospect'},{label:'Customer', value:'Customer'}];

			this.billingCountryList = allCountry;
			this.tepyList = allType;
			this.statusList = allStatus;
		})
	}

	connectedCallback(){
		this.spinner = false;
		this.init();
	}
	
	renderedcallback(){
	}

	rDhandleChange(event){
        const selectedOption = event.detail.value;
        // const selectedOptionValue = this.rDOptions.filter(item =>item['value'] === selectedOption);
        // this.rDUserRoleId = selectedOptionValue[0]['UserRoleId']
		AccountOwnerr({userId: selectedOption})
		.then((data) => {
			let allUsersName = [];
			for(let d in data){
				allUsersName.push({label:data[d]['Name'], value: data[d]['Id']});
				this.orgAndPositonValue.push({Id:data[d]['Id'], org:data[d]['Org_Sub_Region__c'], position:data[d]['Position_ID__c']});
			}
			this.aOOptions = allUsersName;
		})
	}

	aOHandleChange(event){
		this.template.querySelector('[data-id="accountOwner"]').classList.remove('requiredField');
		const selectedOption = event.detail.value;
		const selectedAccountOwnerName = this.aOOptions.filter(item => item['value'] === selectedOption);
		this.aOName = selectedAccountOwnerName[0]['label'];
		this.aOValue = selectedOption;

		const selectedUser = this.orgAndPositonValue.filter(data => {
			if(data['Id'] === selectedOption) return data;
		})

		this.orgValue = selectedUser[0]['org'];
		this.positionValue = selectedUser[0]['position'];
	}

	bCHandelChange(event){this.bCValue = event.detail.value}
	tHandelChange(event){this.tValue = event.detail.value}
	aSHandelChange(event){this.aSValue = event.detail.value}
	
	handelClickBatch(event){
		this.template.querySelector('[data-id="batchIdFilter"]').classList.remove('requiredField');
	}

	handelMoreOption(event){	
		(this.extraFilter === true ? this.extraFilter = false : this.extraFilter = true);
		(this.extraFilter === true ? this.optionText = 'Less Options' : this.optionText = 'More Options');
	}

	statusHandleChange(){
	}

	submit(){
		//if(this.aOName !== undefined){
		if(!this.extraFilter){
			if(this.aOName !== undefined){
        		this.spinner = true;
				const owner = this.aOValue, orgSub = this.orgValue, position = this.positionValue, country = this.	bCValue, typeN = this.tValue, statuse = this.aSValue, ownerName = this.aOName;
				const random = Math.random();
        		this.progressValue = {'owner':owner, 'org':orgSub, 'position':position, 'country':country, 'type':typeN, 'statuse':statuse, 'ownerName':ownerName, 'random':random}      
        		DataTable({dataObj: this.progressValue})
        		.then((data) => {
            		this.dataTableValue = data;
            		try {
                		const selectedEvent = new CustomEvent('progressvaluechange', {
                    		detail: this.dataTableValue
                		});
                		this.dispatchEvent(selectedEvent);

            		} catch (error) {
                	console.log(JSON.stringify(error));
            		}
        		})
			}else{
				this.template.querySelector('[data-id="accountOwner"]').classList.add('requiredField');
				this.showErrorToast('Error', 'Account Owner is required');
			}
		}else {
			const batchId = this.template.querySelector('[data-id="batchIdFilter"]').value;
			const status = this.template.querySelector('[data-id="statusFilter"]').value;
			if(batchId === '' || status === undefined){
				if(batchId === '') this.template.querySelector('[data-id="batchIdFilter"]').classList.add('requiredField');
				if(status === undefined) this.template.querySelector('[data-id="statusFilter"]').classList.add('requiredField');
				this.showErrorToast('Error', 'Batch Id and status is required');
			}else{
				this.spinner = true;
				this.progressValue = {'batchId':batchId, 'status':status}
				DataTable({dataObj: this.progressValue})
        		.then((data) => {
            		this.dataTableValue = data;
            		try {
                		const selectedEvent = new CustomEvent('progressvaluechange', {
                    		detail: this.dataTableValue
                		});
                		this.dispatchEvent(selectedEvent);
            		} catch (error) {
                	console.log(JSON.stringify(error));
            		}
        		})
			}
		}
	}

	showErrorToast(title, mess) {
		const evt = new ShowToastEvent({
			title: title,
			message: mess,
			variant: 'error',
		});
		this.dispatchEvent(evt);
	}
}