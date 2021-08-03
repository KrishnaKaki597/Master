import { LightningElement } from 'lwc';
import getProductData from '@salesforce/apex/ProductBuilderController.getProductList';
import getContentId from '@salesforce/apex/ProductBuilderController.getContentDocumentId';
import {NavigationMixin} from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class ProdBuilderCustomAssembly extends NavigationMixin(LightningElement) {
    searchKey = '';
    filter = '';
    customProdList = [];
    showCustomAssembly = false;
    showAssmblyEditScreen = false;
    assemblyId;
    recordPageUrl;
    connectedCallback(){
        this.getCustomAndStandardProducts(this.searchKey,this.filter,true);
    }
    handleSearchKeyChange(event){
        this.searchKey = event.target.value;
        let keyLength;
        if(!this.searchKey){
            keyLength = 0;
        }
        if(this.searchKey && this.searchKey.length>=2 ){
            this.getCustomAndStandardProducts(this.searchKey,this.filter,true);
        }
        else if(keyLength===0){
            this.getCustomAndStandardProducts(this.searchKey,this.filter,true);
        }
    }
    getCustomAndStandardProducts(searchKey,filter,isAssembly){
        getProductData({
            searchKey: searchKey,
            filterOption: filter,
            isAssembly:isAssembly
        }).then(
            (result) =>{
                this.customProdList = result;
            }).catch((error) => {
                this.customProdList = [];
        });
    }
    resetData(){
        this.searchKey = '';
        this.filter='';
        this.getCustomAndStandardProducts(this.searchKey,this.filter,true);
    }
    createCustomProd(){
        this.showCustomAssembly = true;
    }
    closeChildModal(){
        this.onSuccessToast();
        this.showCustomAssembly = false;
        this.searchKey = '';
        this.filter = '';
        this.getCustomAndStandardProducts(this.searchKey,this.filter,true);
        
    }
    onChildFailure(){
        this.showCustomAssembly = false;
        this.showAssmblyEditScreen = false;
    }
    onSuccessToast(){
        const event = new ShowToastEvent({
            title: 'Product Confirmation',
            message: 'Assembly Added Successfully',
            variant:'success',
            mode:'dismissable'
        });
        this.dispatchEvent(event);
    }
    onFailureToast(){
        const event = new ShowToastEvent({
            title: 'Product Confirmation',
            message: 'Looks like a problem. Please contact your administrator',
            variant:'error',
            mode:'dismissable'
        });
        this.dispatchEvent(event);
    }
    previewAttachment(event){
        let recordId = event.currentTarget.dataset.recordid;
        if(recordId){
            this.getContentDocuments(recordId);
        }
    }
    getContentDocuments(recordId){
        getContentId({
            recordId:recordId
        }).then((result)=>{
            this.navigateToPreivew(result);
        }).catch((error)=>{

        });
    }
    navigateToPreivew(contentDocId){
        this[NavigationMixin.Navigate]({ 
            type:'standard__namedPage',
            attributes:{ 
                pageName:'filePreview'
            },
            state:{ 
                selectedRecordId:contentDocId
            }
        })
    }
    navigateToWebPage(event) {
        let peditAssemblyProd2id = event.currentTarget.dataset.p2id;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: p2id,
                actionName: 'view',
            },
        }).then(url => {
            this.recordPageUrl = url;
        });
    }
    editAssemblyProd(event){
        this.assemblyId = event.currentTarget.dataset.asmbid;
        this.showAssmblyEditScreen = true;
    }
}