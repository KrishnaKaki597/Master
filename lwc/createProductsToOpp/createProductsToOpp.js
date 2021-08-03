import {LightningElement,track,api} from 'lwc';
import getProductData from '@salesforce/apex/AttachProductsToOpportunity.getProductList';
import createOpportunityLineItem from '@salesforce/apex/AttachProductsToOpportunity.saveProductsToOpportunity';
import currentOppLineItems from '@salesforce/apex/AttachProductsToOpportunity.getOpptyLineItems';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CreateProductsToOpp extends LightningElement {
    @track productList = []
    searchKey = null;
    isEdit = false;
    filter = null;
    itemCostPrice = 0;
    salesCostPrice = 0;
    existingItemSalesPrice = 0;
    mapWithProductId = new Map();
    mapWithProdIdProd = new Map();
    mapOfProductsInCart = new Map();
    productsToShow = [];
    showCustomScreen = false;
    showAssemblyScreen = false;
    @api oppId;

    //works on load of component.
    connectedCallback() {
        this.getProductListFromServer(this.searchKey, this.filter,false);
    }

    //picklist values
    get filterOptions(){
        return [ 
                {label:'None',value:''},
                {label: 'Custom Product', value: 'Custom Product'},
                {label: 'Assembly', value: 'Assembly'},
                {label: 'Resource', value: 'Resource'},
                {label: 'Standard Product',value:'Standard Product'}
            ];
    }

    handleProductFitlerChange(event){
        this.filter = event.target.value;
        this.getProductListFromServer(this.searchKey,this.filter,false);
    }

    handleSearchKeyChange(event){
        this.searchKey = event.target.value;
        let keyLength;
        if(!this.searchKey){
            keyLength = 0;
        }
        if(this.searchKey && this.searchKey.length>=2 ){
            this.getProductListFromServer(this.searchKey,this.filter,false);
        }
        else if(keyLength===0){
            this.getProductListFromServer(this.searchKey,this.filter,false);
        }
    }

    //function that brings data from server
    getProductListFromServer(searchKey,filter,isAssembly) {
        let mapOfProducts = this.mapWithProductId;
        let existingProdData = new Map();
        var itemCP = 0;
        var itemSP = 0;
        getProductData({
            searchKey: searchKey,
            filterOption: filter,
            isAssembly:isAssembly
        }).then(
            (result) => {
                this.productList = result.map(function (element) {
                    if(mapOfProducts && mapOfProducts.size>0){
                        if(mapOfProducts.has(element.Id)){
                            element.isSelected = mapOfProducts.get(element.Id);
                        }
                    } else{
                        element.isSelected = false;
                    }
                    element.prodName = element.Name;
                    element.prodCode = element.ProductCode;
                    element.prodId = element.Product2Id;
                    element.vendorName = element.Product2.Vendor_Name__c;
                    element.description = element.Product2.Description;
                    element.prodType = element.Product2.Type_Product__c;
                    element.UnitPrice = element.UnitPrice;
                    element.Id = element.Id;
                    element.isOppProd = true;
                    element.quantity = 0;
                    element.margin = 0;
                    element.salesPrice = 0;
                    element.costPrice = 0;
                    return element;
                });
            }).catch(
                (error) => {}
            );
            if(!this.isEdit){
                currentOppLineItems({
                    opptyId:this.oppId
                }).then((result)=>{
                     result.forEach(function(element){
                        element.isCartProd = true;
                        element.isSelected = true;
                        element.prodName = element.prdName;
                        element.Id = element.pbid;
                        element.prodCode = element.prCode;
                        element.prodId = element.prdId;
                        element.vendorName = element.vdrName;
                        element.description = element.comment;
                        element.UnitPrice = element.prCost;
                        element.cost = element.prCost;
                        element.quantity = element.prQty;
                        element.margin = element.prMargin;
                        element.costPrice = element.prCost;
                        element.salesPrice = element.prSalesCost;
                        itemCP = itemCP + element.costPrice;
                        itemSP = itemSP + element.salesPrice;
                        existingProdData.set(element.Id,element);
                     });
                     if(existingProdData){
                        this.isEdit = true;
                        this.mapWithProdIdProd = existingProdData;
                        this.itemCostPrice = itemCP;
                        this.salesCostPrice = itemSP;
                    }
                }).catch((error)=>{});
            }  
    }

    handleRowSelection(event){
        let recordId = event.currentTarget.dataset.recordid;
        let isProductSelected = event.target.selected;
        if(isProductSelected){ // In case product select checkbox is true
            if(this.mapWithProductId.has(recordId)){
                this.mapWithProductId.set(recordId, !this.mapWithProductId.get(recordId));
            }
        } else{ //In case of product selection is false
            this.mapWithProductId.set(recordId,true);
        }
        this.displayedProductList(recordId);
    }

    displayedProductList(recordId){
        let localMap = this.mapWithProductId;
        let existingDataMap = this.mapWithProdIdProd;
        let removedCost = 0;
        let removedSCost = 0;
        this.productList.map(function(element){
                
                if(localMap && localMap.size>0){
                    if(localMap.has(element.Id)){
                        if(localMap.get(element.Id)){
                            element.isSelected = true;
                        } else{
                            element.isSelected = false;
                            removedCost = removedCost+element.costPrice;
                            removedSCost = removedSCost+element.salesPrice;
                            element.quantity = 0;
                            element.margin = 0;
                            element.salesPrice = 0;
                            element.costPrice = 0;
                        }
                    }
                }
                if(recordId===element.Id){
                    if(!existingDataMap.has(recordId) && element.isSelected ){
                        existingDataMap.set(element.Id,element);
                    } else if(existingDataMap.has(recordId) && !element.isSelected){
                        existingDataMap.delete(recordId);
                    }
                } 
                return element;
        });
        if(this.itemCostPrice){
            this.itemCostPrice = this.itemCostPrice - removedCost;
            this.salesCostPrice = this.salesCostPrice - removedSCost;
        }
        if(existingDataMap && existingDataMap.size>0){
            this.mapWithProdIdProd = existingDataMap;
        }
    }


    onClickSaveHandler(){
        let elementsToSend = this.productsToShow;
        console.log('elements in save mehtod = '+JSON.stringify(elementsToSend))
        if(elementsToSend.length>0){
            createOpportunityLineItem({productsInContext:JSON.stringify(elementsToSend),parentId:this.oppId}).then((result)=>{
                if(result==='OK'){
                    this.onSuccessToast();
                    this.closeQuickModal();
                } else{
                    this.onFailureToast();
                    this.closeQuickModal();
                }
            }).catch((error)=>{
                console.log('error'+error);
            });
         }
        else{
            createOpportunityLineItem({productsInContext:'',parentId:this.oppId}).then((result)=>{
                if(result==='OK'){
                    this.onSuccessToast();
                    this.closeQuickModal();
                } else{
                    this.onFailureToast();
                    this.closeQuickModal();
                }
            }).catch((error)=>{
                console.log('error'+error);
            });
        }
       
    }

    onClearHandler(){
        this.searchKey = '';
        this.filter = '';
        this.getProductListFromServer(this.searchKey,this.filter,false);
        this.mapWithProductId = new Map();
        this.productList = [];
        this.mapWithProdIdProd = new Map();
        this.itemCostPrice = 0;
        this.salesCostPrice = 0;
        
    }

    get prodListToShow(){
        let mapOfProductsInCart = this.mapWithProdIdProd;
        let currentProdList = [];
        currentProdList = Array.from(mapOfProductsInCart.values());
        console.log('elements from current prodList = '+currentProdList);
        return currentProdList;
    }

    closeQuickModal(event){
        this.dispatchEvent(new CustomEvent('closeAction'));
    }

    handleQtyMarginChange(event){
        let context= event.currentTarget.dataset.context
        let recordId = event.currentTarget.dataset.recordid;
        console.log('context = '+context+' recordId = '+recordId);
        let value = event.target.value;
        let costP = 0;
        let salesP = 0;
        let selectedArrayList = Array.from(this.mapWithProdIdProd.values());
        let elementsToPush= [];
        selectedArrayList.filter(function(element){
            if(element.Id===recordId){
                if(context === 'quantity'){
                    element.quantity = value;
                    console.log('currernt quantity = '+element.quantity);
                } else if(context==='margin'){
                    element.margin = value;
                }
                console.log('valuees of element.UnitPrice = '+element.UnitPrice+' quantity = '+element.quantity);
                let currentCost = (element.UnitPrice*element.quantity);
                element.costPrice = currentCost;
                element.salesPrice = currentCost+((element.margin/100)*(currentCost));
            }
            return element;
        });
        if(selectedArrayList){
            selectedArrayList.forEach(function(element){
                elementsToPush.push({Id:element.Id,quantity:element.quantity,margin:element.margin,salesPrice:element.salesPrice});
                costP = costP+element.costPrice;
                salesP = salesP + element.salesPrice;
                return element;
            });
            console.log('The cosot price = '+costP + 'sales price = '+salesP);
            if(costP){
                this.itemCostPrice = costP;
                this.salesCostPrice = salesP;
            }else{
                this.itemCostPrice = 0;
                this.salesCostPrice = 0;
            }
        }
        if(elementsToPush.length>0){
            this.productsToShow = elementsToPush;
        }
    }

    deleteLineItem(event){
        let prodInCartSize = this.mapWithProdIdProd.size;
        let commonMap = new Map();
        let recordId = event.currentTarget.dataset.recordid;
        let elementToRemove;
        let costToRemove = 0;
        let salesCostToRemove = 0;
        this.mapWithProdIdProd.forEach((value,key)=>{
            if(key!==recordId){
                commonMap.set(key,value);
            }
            if(key===recordId){
                elementToRemove = value;
                costToRemove = costToRemove + elementToRemove.costPrice;
                salesCostToRemove = salesCostToRemove + elementToRemove.salesPrice;
            }
        });
        if(costToRemove){
            if(costToRemove<this.itemCostPrice){
                this.itemCostPrice = this.itemCostPrice - costToRemove;
                this.salesCostPrice = this.salesCostPrice-salesCostToRemove;
            }else{
                this.itemCostPrice = 0;
                this.salesCostPrice = 0;
            }
        }
        // this.mapWithProdIdProd.delete(recordId);
        // if(prodInCartSize>0){
        //    if(productsInCart.has(recordId)){

        //        //productsInCart.delete(recordId);
        //    }
        // }
        // if(productsInCart.size>0){
        //     this.mapWithProdIdProd = productsInCart;
        // }else{
        //     this.mapWithProdIdProd = new Map();
        // }
        this.mapWithProdIdProd = commonMap;
    }

    onSuccessToast() {
        const event = new ShowToastEvent({
            title: 'Product List Confirmation',
            message: 'Products Added To Opportunity Successfully',
            variant:'success',
            mode:'dismissable'
        });
        this.dispatchEvent(event);
    }

    onFailureToast(){
        const event = new ShowToastEvent({
            title: 'Product List Confirmation',
            message: 'Looks like a problem. Check with your administrator.',
            variant:'error',
            mode:'dismissable'
        });
        this.dispatchEvent(event);
    }

    showCustomProductScreen(event){
        this.showCustomScreen = true;
    }
    showCustomAssemblyScreen(){
        this.showAssemblyScreen = true;
    }

    closeChildModal(event){
        this.showCustomScreen = false;
        this.getProductListFromServer('','',false);
    }

    updateChildModal(){
        this.showAssemblyScreen = false;
        this.getProductListFromServer('','',false);
    }
    updateChildFailure(){
        this.showCustomScreen = false;
        this.showAssemblyScreen = false;
    }

    onChildFailure(){
        this.showCustomScreen = false;
        this.showAssemblyScreen = false;
    }    
    refreshTable(){
        this.searchKey = '';
        this.filter = '';
        this.getProductListFromServer('','',false);   
    }
   
}