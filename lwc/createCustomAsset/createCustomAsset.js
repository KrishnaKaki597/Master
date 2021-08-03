import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CreateCustomAsset extends LightningElement {
    objectApiName = 'Product2';
    onAssetCreation(event){
        if(event.detail.id){
            this.onSuccessToast();
        }else{
            this.onFailureToast();
        }
    }
    onSuccessToast(){
        const event = new ShowToastEvent({
            title: 'Asset Confirmation',
            message: 'Asset Added Successfully',
            variant:'success',
            mode:'dismissable'
        });
        this.dispatchEvent(event);
    }
    onFailureToast(){
        const event = new ShowToastEvent({
            title: 'Asset Confirmation',
            message: 'Looks like a problem. Please contact administrator',
            variant:'success',
            mode:'dismissable'
        });
        this.dispatchEvent(event);
    }
    overDoCancel(){
        this.fireFailureEvent();
    }
    fireFailureEvent(event){
        this.dispatchEvent(new CustomEvent('success'));
    }
    fireSuccessEvent(event){
        this.dispatchEvent(new CustomEvent('failure'));
    }
    
}