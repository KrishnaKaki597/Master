import { LightningElement } from 'lwc';
import getProductData from '@salesforce/apex/ProductBuilderController.getProductList';
import getContentId from '@salesforce/apex/ProductBuilderController.getContentDocumentId';
import {NavigationMixin} from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class ProductBuilderCustomProduct extends NavigationMixin(LightningElement) {
    searchKey = '';
    filesList =[]
    filter = '';
    customProdList = [];
    showCustomScreen = false;
    recordPageUrl;
    editScreen = false;
    prodId;
    connectedCallback(){
        this.getCustomAndStandardProducts(this.searchKey,this.filter,false);
    }
    handleSearchKeyChange(event){
        this.searchKey = event.target.value;
        let keyLength;
        if(!this.searchKey){
            keyLength = 0;
        }
        if(this.searchKey && this.searchKey.length>=2 ){
            this.getCustomAndStandardProducts(this.searchKey,this.filter,false);
        }
        else if(keyLength===0){
            this.getCustomAndStandardProducts(this.searchKey,this.filter,false);
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
        this.getCustomAndStandardProducts(this.searchKey,this.filter,false);
    }
    createCustomProd(){
        this.showCustomScreen = true;
    }
    closeChildModal(){
        this.getCustomAndStandardProducts(this.searchKey,this.filter,false);
        this.showCustomScreen = false;
       
    }
    onChildFailure(){
        this.showCustomScreen = false;
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
        let p2id = event.currentTarget.dataset.p2id;
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
    editProductScreen(event){
        this.editScreen = true;
        let p2id = event.currentTarget.dataset.p2id;
        this.prodId = p2id;
    }
    closeEditScreen(event){
        this.editScreen = false;
        eval("$A.get('e.force:refreshView').fire();");
    }
    
}