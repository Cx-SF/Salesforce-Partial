import { LightningElement, api, track } from 'lwc';

export default class PopUpMessage extends LightningElement {
    @api popmessage;
    message;
    title;
    @track isModalOpen = true; //Boolean tracked variable to indicate if modal is open or not default value is false as modal is closed when page is loaded
    // openModal() {
    //     // to open modal set isModalOpen tarck value as true
    //     this.isModalOpen = true;
    // }
    connectedCallback(){
        this.message = this.popmessage['meesage'];
        this.title = this.popmessage['title'];
	}

    closeModal() {
        // to close modal set isModalOpen tarck value as false        
        try {
            const selectedEvent = new CustomEvent('popupchange', {
                detail: (this.title == 'In Progress') ? 'filter' : 'table'
            });
            this.dispatchEvent(selectedEvent);

        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }
    submitDetails() {
        // to close modal set isModalOpen tarck value as false
        //Add your code to call apex method or do some processing
        try {
            const selectedEvent = new CustomEvent('popupchange', {
                detail: (this.title == 'In Progress') ? 'filter' : 'table'
            });
            this.dispatchEvent(selectedEvent);

        } catch (error) {
            console.log(JSON.stringify(error));
        }
    }
}