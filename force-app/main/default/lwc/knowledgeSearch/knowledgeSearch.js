import { LightningElement, track, wire, api } from 'lwc';
import * as navigation from 'lightning/navigation';
import KnowledgeRecordTypes from '@salesforce/apex/knowledgeSearchController.KnowledgeRecordTypes';
import KnowledgeArticles from '@salesforce/apex/knowledgeSearchController.KnowledgeArticles';

//import getPicklistValues from '@salesforce/apex/knowledgeSearchLWC.getPicklistValues_old';

export default class knowledgeSearch extends navigation.NavigationMixin(LightningElement) {
    @track article;
    @track articleList = [];
    @track boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
    @track listBoxClass = 'slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid listbox_close';

    @track results;

    //@track cible = 'Tous';
    @track rt = 'All';
    @track pa = '--None--';
    @track rtList = [];
    @track paList = ['Account management','Certificate','General','Lesson','Login','UI'];t
    @track lastInput = '';

    @api ifOnFocus;
    @api IfToShowIcon = false;
    @api displayCard;
    @api ifCommunityHeader;
    @api displayCategory;
    @api displayProductArea;
    @api displayHeader;
    @api productArea;    
    parameters = {};

    

       
    
    connectedCallback() {
        window.addEventListener('popstate', (event) => {
            console.log("location: " + document.location + ", state: " + JSON.stringify(event.state));
          });
         

          this.IfToShowIcon = true;  
                
       this._pushState();
       console.log('productArea & subProductArea change to null from ' + localStorage.getItem('productArea') + ' & ' + localStorage.getItem('subProductArea'));
       localStorage.setItem('productArea',null);
       localStorage.setItem('subProductArea',null);
      
       this.parameters = this.getQueryParameters();
        console.log('Query String Parameters In LWC :',this.parameters);
       

       if(  this.ifOnFocus == undefined){
        this.ifOnFocus = true;        
       }
       if(  this.ifCommunityHeader == undefined){
        this.ifCommunityHeader = false;        
       }
       localStorage.setItem('ifCommunityHeader',this.ifCommunityHeader);
       if(!this.ifOnFocus && !this.ifCommunityHeader){
        console.log('recordTypeName change to null from ' + localStorage.getItem('recordTypeName'));
        localStorage.setItem('recordTypeName',null);
       }      
    }

    get componentClass() {
        return (this.displayCard ? 'slds-page-header' : 'slds-m-around_medium');
    }

    @wire(KnowledgeRecordTypes)
    wiredRecordTypes({ error, data }) {        
        if (data) {
            this.rtList = data;
            console.log('data', data);
            this.error = undefined;
        }
        if (error) {
            this.error = error;
            console.log('data error', error);
            this.rtList = undefined;
        }
    };

    handleKnowledgeArticles(data){
        if(data.length > 0){
            this.articleList = [];  
        }else{
            this.articleList = undefined; 
        }
               
            for (let article of data) {
                 
                let myArticle = {};
                myArticle.data = article;

               
                // Get article url
                
                this.KnowledgePageRef = {
                    type: "standard__recordPage",
                    attributes: {
                        "recordId": article.Id,
                        "objectApiName": "Knowledge__kav",
                        "actionName": "view"
                    }
                };
               
                
                this[navigation.NavigationMixin.GenerateUrl](this.KnowledgePageRef)
                    .then(articleUrl => {
                        myArticle.url = articleUrl;
                        this.articleList.push(myArticle);                      
                        this.listBoxClass = 'slds-slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid listbox_open';
                        this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open';                       
                    });
                    
            }

    }
    
    @wire(KnowledgeArticles, { input: '$article', cat: localStorage.getItem('recordTypeName'), productArea: localStorage.getItem('productArea'), subProductArea: localStorage.getItem('subProductArea'),ifCommunityHeader: localStorage.getItem('ifCommunityHeader') })
    wiredArticles({ error, data }) {       
        console.log('data',data);
        if(  this.lastInput == undefined){
            this.lastInput = '';        
           }
        
        if (error || (this.article == '' && this.lastInput.length == 1)) {
            console.log('last Input :' + this.lastInput);
            console.log('current Input :' + this.article);
            this.article = undefined;
            this.error = error;
            this.articleList = undefined;
            this.listBoxClass = 'slds-slds-dropdown slds-dropdown_length-with-icon-7 slds-dropdown_fluid listbox_close';
            this.boxClass = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus';
        }
        else if (data) {            
            
                this.handleKnowledgeArticles(data); 
                this.error = undefined;                                  
            
        }
        this.lastInput = this.article;
        console.log('last Input :' + this.lastInput);
        
    }

    

    changeHandler(event) {
        this.article = event.target.value;        
        console.log('recordTypeName',localStorage.getItem('recordTypeName'));
        console.log('Product Area',localStorage.getItem('productArea'));
        console.log('Sub Product Area',localStorage.getItem('subProductArea'));
        console.log('Subject', this.article);                        
        const value = this.article;
        // Handle Search Icon In Communiity Header
        if(value.length > 0){
            this.IfToShowIcon = false; 
           
        }else{
            this.IfToShowIcon = true;            
        }
        // Fire function to other component - passing user input
        const valueChangeEvent = new CustomEvent("valuechange", {
            detail: { value }
          });
          // Fire the custom event
          this.dispatchEvent(valueChangeEvent);
        
    }

    changeHandlerOnFocus(event){       
        console.log('ifOnFocus', this.ifOnFocus);       
        if(this.ifCommunityHeader) {
            this.GetCurrentParamFromCommunityHeaderSearchKnowledge();
        }            
        if((!this.ifOnFocus && event.target.value == '') || (this.ifOnFocus && (localStorage.getItem('productArea') == null || localStorage.getItem('productArea') == '' || localStorage.getItem('productArea') == 'null'))){            
            console.log('Exit change Handler On Focus'); 
           return;
        }                
        this.article = event.target.value;   
        const value = this.article;
         // Fire function to other component - passing user input
         const valueChangeEvent = new CustomEvent("valuechange", {
            detail: { value }
          });
          // Fire the custom event
          this.dispatchEvent(valueChangeEvent);
        console.log('input :', this.article);           
    }

    deleteInput(event){
        console.log('delete input :', tmp.innerText); 
        var tmp = document.getElementsByClassName('customSearchInput')[0];
        console.log('delete input :', tmp); 
        console.log('delete input :', tmp.value); 
        tmp.value = '';
        
    }

    changeHandlerOnBlur(event){
        this.article = undefined;
        console.log('blur input :', this.article); 
    }

    handleCible(event) {
        this.rt = event.target.value;       
        console.log('rt', this.rt);
    }

    handleCiblePA(event) {       
        this.pa = event.target.value;
        console.log('pa', this.pa);
    }

    redirectToArticle(event) {
        // Navigate to the CaseComments related list page
        // for a specific Case record.
        event.preventDefault();
        event.stopPropagation();        
        this[navigation.NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.currentTarget.dataset.toto,
                objectApiName: 'Knowledge__kav',
                actionName: 'view'
            }
        }).then(url => {
            console.log('url',url);
            window.open(url, "_blank");
        });
                
    }

    // Get Current Param From Community Header Search Knowledge

    GetCurrentParamFromCommunityHeaderSearchKnowledge(){
      var currentUrl = window.location.href;                      
      currentUrl = currentUrl.split('/'); 
      var index = currentUrl.length - 1;   
      var currentParam = currentUrl[index].split('?')[0];   
      console.log('currentParam',currentParam);
      console.log('currentParam length',currentParam.length);
      console.log('recordTypeName',localStorage.getItem('recordTypeName'));
      console.log('test ',this.checkIfEquals(currentParam ,localStorage.getItem('recordTypeName')));
      if(currentUrl[index - 1] == "article"){
        console.log('article details page' );
      }
      else if(currentUrl[index - 2] == "case" || currentParam == "user-management" || currentParam == "view-my-comm-cases" || currentParam == "all-my-comm-cases" || currentParam == "my-account-cases" || currentParam == "submit-new-comm-case" || currentParam == "Report List" || currentParam == "Error" || currentParam == 'knowledge-base' || currentParam == 'home-public-knowledge-base' || currentParam == null || currentParam == '' || currentParam == undefined || currentParam.length == 0 ){
        localStorage.setItem('recordTypeName',null);
        localStorage.setItem('productArea',null);
        localStorage.setItem('subProductArea',null);
        console.log('recordTypeName',null);
      }
      else if((localStorage.getItem('recordTypeName') === null || localStorage.getItem('recordTypeName') == "null") || this.checkIfEquals(currentParam ,localStorage.getItem('recordTypeName')))  {
        localStorage.setItem('recordTypeName',currentParam.replaceAll('-','_') + '__c');
        localStorage.setItem('productArea',null);
        console.log('recordTypeName',localStorage.getItem('recordTypeName') );
      }
      else if((localStorage.getItem('productArea') === null || localStorage.getItem('productArea') == "null")  || this.checkIfEquals(currentParam,localStorage.getItem('productArea'))){
        localStorage.setItem('productArea',currentParam.replaceAll('-','_')  + '__c');
        localStorage.setItem('subProductArea',null);
        console.log('productArea',localStorage.getItem('productArea'));
      }
      else if((localStorage.getItem('subProductArea')  === null || localStorage.getItem('subProductArea') == "null")  || this.checkIfEquals(currentParam,localStorage.getItem('subProductArea'))){
        localStorage.setItem('subProductArea',currentParam.replaceAll('-','_')  + '__c');
        console.log('subProductArea',localStorage.getItem('subProductArea'));
      }     
    }

    
    checkIfEquals(currentParam , currentLocalStorage){
        console.log(currentParam +'==='+ currentLocalStorage.replace('__c',''));
        console.log(currentParam +'==='+ currentLocalStorage.replace('__c','').replaceAll('_','-'));
        if(currentParam === currentLocalStorage.replace('__c','')){
            return true;
        }else  if(currentParam === currentLocalStorage.replace('__c','').replaceAll('_','-')){
            return true;
        }else{
            return false;
        }
    }

    checkIfRecordTypeName(currentParam){
        if(currentParam == 'cxsast' || currentParam == 'cxiast' || currentParam == 'cxsca' || currentParam == 'codebashing' || currentParam == 'cxosa'){
            return true;
        }
        else{
            return false;
        }

    }
    
    // Get Query String Parameters From URL
    getQueryParameters() {

        var params = {};
        var search = location.search.substring(1);

        if (search) {
            params = JSON.parse('{"' + search.replace(/&/g, '","').replace(/=/g, '":"') + '"}', (key, value) => {
                localStorage.setItem(key,value);
                console.log(key,localStorage.getItem(key));
                return key === "" ? value : decodeURIComponent(value)
            });
        }

        return params;
    }

    
/**
 * Pushes the state of the component (the page number) as an entry to the 
 * browser's history.
 */
 _pushState() {
    
    /* The Lightning platform or other components may also be 
        using the state object. A copy is created so no existing data 
        is lost 
    const state = Object.assign({}, history.state);
    state.pageNumber = this.pageNumber;
    history.pushState(state, '');
    console.log('_pushState');
    */
    console.log('I am called from pushStateHook in LWC');
}

 // Get Query String Parameters From URL
 getCase(id) {
    const Http = new XMLHttpRequest();
    const url='https://checkmarx--uat.my.salesforce.com/services/data/52.0/sobjects/Case/' + id;        
    Http.open("GET", url);
    Http.send();

    Http.onreadystatechange = (e) => {
    console.log(Http.responseText)
     }
}

}