import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import init from '@salesforce/apex/CaseActionButtonsLayout_Ctrl.loadData';
import close from '@salesforce/apex/CaseActionButtonsLayout_Ctrl.closeCase';

export default class CaseActionButtonsLayout extends LightningElement {
    _recordId;
    caseRecord;
    canClose = false;
    canEscalate = false;
    showEscalationFlow = false;
    disableCloseBtn = false;
    disableEscalateBtn = false;
    escalateBtnLabel = 'Escalate Case';
    escalateBtnIcon = 'utility:add';

    @api get recordId(){
        return this._recordId;
    }

    set recordId(value){
        this._recordId = value;
    }

    get flowVariables(){
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.caseRecord.Id
            }
        ];
    }

    handleClose(e){
        this.disableCloseBtn = true;
        close({ c : this.caseRecord })
        .then((data) => {
            if (data.success){
                const event = new ShowToastEvent({
                    title: 'Success',
                    variant: 'success',
                    message: 'Case successfully Closed'
                });
                this.dispatchEvent(event);
                this.canClose = false;
                this.canEscalate = false;
            } else {
                const event = new ShowToastEvent({
                    title: 'Something went wrong',
                    variant: 'error',
                    message: data.error_message
                });
                this.dispatchEvent(event);
                console.log('Exception closing case: ' + JSON.stringify(err));    
            }
        })
        .catch((err) => {
            const event = new ShowToastEvent({
                title: 'Get Help',
                variant: 'error',
                message: 'Something went wrong, please contact an Administrator.'
            });
            this.dispatchEvent(event);
            console.log('Exception closing case: ' + JSON.stringify(err));
        });
    }

    escalateFinished(e){
        if (e.detail.status === 'FINISHED') {
            this.disableCloseBtn = false;
            this.showEscalationFlow = false;
            //this.initialize();
            window.location.reload();
        }
    }

    closeEscalationModal(e){
        this.disableCloseBtn = false;
        this.showEscalationFlow = false;
    }

    handleEscalate(e){
        this.disableCloseBtn = true;
        this.showEscalationFlow = true;
    }

    initialize(){
        init({ cId : this._recordId })
        .then((data) => {
            console.log('action buttons layout init data: ' + JSON.stringify(data));
            if (data.success){
                this.caseRecord = data.case;
                this.canClose = (!data.closed);
                this.canEscalate = data.allow_escalate;
                if (data.case.Cx_Customer_Escalation__c){
                    this.escalateBtnLabel = 'Escalated';
                    this.escalateBtnIcon = 'utility:check';
                } else {
                    this.escalateBtnLabel = 'Escalate Case';
                    this.escalateBtnIcon = 'utility:add';
                }
            } else {
                console.log('Error loading action buttons layout: ' + data.error_message);
            }
        })
        .catch((err) => { console.log('Exception loading action buttons layout: ' + JSON.stringify(err)); });
    }

    connectedCallback(){
        this.initialize();
    }

    renderedCallback(){

    }
}