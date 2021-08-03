import { LightningElement } from 'lwc';
import {NavigationMixin} from 'lightning/navigation';
import recentOpportunities from '@salesforce/apex/ProductBuilderController.getRecentOpportunities';
export default class ProductBuilderOppList extends NavigationMixin(LightningElement) {
    opportunityList = [];
    showCustomOpp = false;
    recordPageUrl;
    editScreen = false;
    opptyId;
    connectedCallback(){
        this.opportunityListToShow();
    }
    closeChildModal(){
        this.showCustomOpp = false;
        this.opportunityListToShow();
    }
    onChildFailure(){
        this.showCustomOpp = false;
        this.opportunityListToShow();
    }
    createCustomOpp(){
        this.showCustomOpp = true;
    }
    opportunityListToShow(){
        recentOpportunities({}).then((result)=>{
            this.opportunityList = result;
        }).catch((error)=>{ 
            this.opportunityList = [];
        });
    }
    resetData(){
        this.opportunityListToShow();
    }
    navigateToWebPage(event) {
        let optyid = event.currentTarget.dataset.optyid;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: optyid,
                actionName: 'view',
            },
        }).then(url => {
            this.recordPageUrl = url;
        });
    }
    editOpportunity(event){
        this.opptyId = event.currentTarget.dataset.optyid;
        this.editScreen = true;
    }
    closeEditScreen(event){
        this.editScreen = false;
        eval("$A.get('e.force:refreshView').fire();");
    }
}