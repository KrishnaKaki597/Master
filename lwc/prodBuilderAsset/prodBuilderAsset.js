import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import recentAssets from '@salesforce/apex/ProductBuilderController.getRecentAssets';
export default class ProdBuilderAsset extends NavigationMixin(LightningElement){
    assetsList = [];
    showCustomScreen = false;
    recordPageUrl;
    editScreen = false;
    connectedCallback(){
        this.getLatestAssets();
    }
    getLatestAssets(){
        (recentAssets)({}).then((result)=>{
            this.assetsList = result;
            this.assetsList.map(function(element){
                return element;
            })
        }).catch((error)=>{

        });
    }
    createNewAsset(){
        this.showCustomScreen = true;
    }
    closeChildModal(){
        this.showCustomScreen = false;
        this.getLatestAssets();
    }
    onChildFailure(){
        this.showCustomScreen = false;
    }
    resetData(){
        this.getLatestAssets();
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