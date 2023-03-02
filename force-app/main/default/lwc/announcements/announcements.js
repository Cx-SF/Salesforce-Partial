import {  LightningElement, api , wire, track } from 'lwc';
import * as navigation from 'lightning/navigation';
import getCarouselAnnouncement from '@salesforce/apex/lightningCarouselController.getCarouselAnnouncement';

export default class Announcements extends navigation.NavigationMixin(LightningElement) {

    @track announcement;
    @track announcements = [];      

    @wire(getCarouselAnnouncement, { AnnouncementType: 'Maintenance' })
    wiredAnnouncements({ error, data }) {
        console.log('data',JSON.stringify(data));
        if (data) {
            
            for (let announcement of data) {
                let myAnnouncement = {};
                myAnnouncement.data = announcement;

                // Get announcement url
                this.AnnouncementPageRef = {
                    type: "standard__recordPage",
                    attributes: {
                        "recordId": announcement.Id,
                        "objectApiName": "Carousel_Announcement__c",
                        "actionName": "view"
                    }
                };

                this[navigation.NavigationMixin.GenerateUrl](this.AnnouncementPageRef)
                    .then(announcementUrl => {
                        myAnnouncement.url = announcementUrl;
                        this.announcements.push(myAnnouncement);                        
                    });
            }

            this.error = undefined;
        }
        if (error) {
            this.error = error;
            this.announcements = undefined;           
        }
    }

}