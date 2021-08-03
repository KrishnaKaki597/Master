import { LightningElement } from 'lwc';
import customProdut from '@salesforce/apex/CreateCustomProduct.createPriceBooksEntry';
import attachDocument from '@salesforce/apex/CreateCustomProduct.attachContentToProduct';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CreateCustomProduct extends LightningElement {
    objectApiName = 'Product2';
    documentIdList = [];
    onProductCreation(event){
       let recordId = event.detail.id;
       let cost = (event.detail.fields.Cost__c.value?event.detail.fields.Cost__c.value:0);
       if(recordId){
            this.onSuccessToast();
            this.createPriceBookEntry(recordId,cost); 
       }
       if(recordId && this.documentIdList.length>0){
        this.attachContentVersion(this.documentIdList,recordId);
       }
    }
    handleUploadFinished(event){
        const uploadFiles = event.detail.files;
        if(uploadFiles.length>0){
            uploadFiles.forEach(element=>this.documentIdList.push(element.documentId));
        }
    }
    createPriceBookEntry(recordId,cost){
        customProdut({productId:recordId,unitCost:cost}).then((result)=>{
           if(result==='200'){
               this.fireSuccessEvent();
           } else{
                this.onFailureToast();
                this.fireFailureEvent();
           }
        }).catch((error)=>{
            this.onFailureToast();
            this.fireFailureEvent();
        });
    }

    attachContentVersion(docList,recordId){
        attachDocument({
            contentList:docList,
            productId:recordId
        }).then((result)=>{
            console.log(result);
        }).catch((error)=>{

        });
    }

    overrideCancel(event){
        this.fireFailureEvent();
    }

    fireSuccessEvent(){
        this.dispatchEvent(new CustomEvent('success'));
    }

    fireFailureEvent(){
        this.dispatchEvent(new CustomEvent('failure'));
    }
    onSuccessToast(){
        const event = new ShowToastEvent({
            title: 'Product Creation',
            message: 'Product Created Successfully',
            variant:'success',
            mode:'dismissable'
        });
        this.dispatchEvent(event);
    }
    onFailureToast(){
        const event = new ShowToastEvent({
            title: 'Product Creation',
            message: 'Looks like a problem. Please contact your administrator',
            variant:'error',
            mode:'dismissable'
        });
        this.dispatchEvent(event);
    }
}