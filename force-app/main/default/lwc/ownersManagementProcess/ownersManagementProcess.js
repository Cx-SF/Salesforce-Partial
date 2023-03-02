import {LightningElement, wire, track,api} from 'lwc';


export default class OwnersManagementProcess extends LightningElement {
	filter = true;
	popUp = false;
	progressValue;
	popUpMessage;

	handelProgressValueChange(event){
		this.filter = false;
		const data = event.detail;
		this.progressValue = data;		
	}

	handelTableChange(event){
		this.popUp = true;
		const data = event.detail;
		this.popUpMessage = data;
	}

	handelError(event){
		this.popUp = true;
		const data = event.detail;
		this.popUpMessage = data;
	}

	handelPopUpChange(event){
		if(event.detail == 'filter') {
			this.filter = true; 
			
		}else{
			this.filter = false;
		}
		this.popUp = false;		
	}
}