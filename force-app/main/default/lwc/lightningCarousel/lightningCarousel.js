import {  LightningElement, api , wire, track } from 'lwc';
import * as navigation from 'lightning/navigation';
import getCarouselAnnouncement from '@salesforce/apex/lightningCarouselController.getCarouselAnnouncement';


export default class LightningCarousel extends navigation.NavigationMixin(LightningElement) {
  
    @api CarouselWidth;   
    @api dynamicWidthClass = 'slds-size_3-of-4 customBoxClass';
    @api announcementType = 'Announcement';
    @api boxTitle = 'Announcement';
    @api ifToShowAnnouncementIcon = false;
    @api helperClassForTitle;
    @track announcement;
    @track announcements = [];      
    

    
    @wire(getCarouselAnnouncement, { AnnouncementType: '$announcementType' })
    wiredAnnouncements({ error, data }) {
        console.log('this.announcementType','$announcementType');
        console.log('data',JSON.stringify(data));
        if (data) {
            this.helperClassForTitle = 'boxTitleLabel ' + this.boxTitle;
            if(this.boxTitle == 'Announcement'){
                this.ifToShowAnnouncementIcon = true;
            }
            if(this.CarouselWidth == '100'){
                this.dynamicWidthClass = 'slds-size_4-of-4 customBoxClass';
             }
             if(this.CarouselWidth == '50'){
                 this.dynamicWidthClass = 'slds-size_2-of-4 customBoxClass';
              }

              
            for (let announcement of data) {
                let myAnnouncement = {};
                myAnnouncement.data = announcement;
               
                // Get announcement url                 
                if(announcement.Target_Link_Type__c === 'Knowledge'){                     
                    this.AnnouncementPageRef = {                        
                        type: "standard__recordPage",                    
                        attributes: {
                            "recordId": announcement.Knowledge__c,
                            "objectApiName": "Knowledge__kav",
                            "actionName": "view"
                            }
                   };
                  
                }else {                     
                    this.AnnouncementPageRef = {                                                                            
                        type: 'standard__webPage',
                        attributes: {
                            url: announcement.Target_Link__c
                        }                    
                    };
                }
                

                this[navigation.NavigationMixin.GenerateUrl](this.AnnouncementPageRef)
                    .then(announcementUrl => {                         
                        myAnnouncement.url = announcementUrl;     
                        console.log('myAnnouncement.url',myAnnouncement.url);                 
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