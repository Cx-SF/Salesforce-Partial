import { LightningElement, api, track } from 'lwc';
import startProcess from '@salesforce/apex/AutoSolvedProcess.startProcess';
import getBatchInfo from '@salesforce/apex/AutoSolvedProcess.getBatchInfo';

export default class AutoSolveProcess extends LightningElement {
    @track classRunsList = [];
    // @track progress = 0;
    // 'Progress': this.progress + '%',
    @track status = 'Holding';
    errorMes = '';
    numOfError = 0;
    batchProcessId;
    value = '';

    submitHandler(){
        const cahseId = this.template.querySelector(".caseInput");
        console.log('cahseId: ' + cahseId.value);
        
        if(cahseId.value != undefined && cahseId.value != ''){  
            startProcess({'caseId': cahseId.value}).then((data)=>{
                //if(data.Succses){
                    //console.log('saccses');
                //}
                let classObj = {'id': data.batchId, 'className': 'AutoSolvedProcessBatch - case: ' + cahseId.value , 'Status':this.status, 'NumberError': this.numOfError, 'Error': this.errorMes};
                this.classRunsList.push(classObj);

                this.batchProcessId = data.batchId;
                cahseId.value = '';
                this.setInfoTimeout();
            })       
        }
    }

    setInfoTimeout(){
        setTimeout(() => {
            this.getInfo();
        }, 3000)
    }

    getInfo(){
        for(let obj in this.classRunsList){
            console.log('obj: ' + this.classRunsList[obj].id);

            if(this.classRunsList[obj].Status != 'Completed' &&  this.classRunsList[obj].Status != 'Failed'){ 
                getBatchInfo({'batchProcessId': this.classRunsList[obj].id}).then((result) => {  
                    console.log('NumberOfErrors: ' + result.NumberOfErrors); 
                    this.classRunsList[obj].NumberError = result.NumberOfErrors;
                    this.classRunsList[obj].Status = result.Status;                
                    this.setInfoTimeout();
                })    
            }
        }
    }
}