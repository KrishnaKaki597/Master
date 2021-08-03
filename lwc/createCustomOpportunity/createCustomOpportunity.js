import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CreateCustomOpportunity extends LightningElement {
    objectApiName = 'Opportunity';

    onOpportunityCreation(event){ 
        if(event.detail.id){
            this.onSuccessToast();
        } else{
            this.onFailureToast();
        }
    }
    onSuccessToast(){
        const event = new ShowToastEvent({
            title: 'Opportunity Creation',
            message: 'Opportunity Created Successfully',
            variant:'success',
            mode:'dismissable'
        });
        this.dispatchEvent(event);
    }
    overrideCancel(event){
        this.fireFailureEvent();
    }
    onFailureToast(){
        const event = new ShowToastEvent({
            title: 'Opportunity Creation',
            message: 'Looks like a problem. Please contact your administrator',
            variant:'error',
            mode:'dismissable'
        });
        this.dispatchEvent(event);
    }
    fireFailureEvent(event){
        this.dispatchEvent(new CustomEvent('success'));
    }
    fireSuccessEvent(event){
        this.dispatchEvent(new CustomEvent('failure'));
    }
}