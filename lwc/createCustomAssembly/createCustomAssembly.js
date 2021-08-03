import { LightningElement,track } from 'lwc';
import getProductData from '@salesforce/apex/AttachProductsToOpportunity.getProductList';
import customProduct from '@salesforce/apex/CreateCustomProduct.createAssemblyLineItems';
import attachDocument from '@salesforce/apex/CreateCustomProduct.attachContentToProduct';
export default class CreateCustomAssembly extends LightningElement {
    objectApiName = 'Assembly__c';
    documentIdList = [];
    @track productList = [];
    searchKey = null;
    filter = null;
    itemCostPrice = 0;
    salesCostPrice = 0;
    mapWithProductId = new Map();
    mapWithProdIdProd = new Map();
    productsToShow = [];
    itemsCount = 0;
    standardHours = 0;
    overtimeHours = 0;
    timeAndHalfHours = 0;
    standardPrice = 0;
    overtimePrice = 0;
    timePrice = 0;
    standardCost = 0;
    overtimeCost = 0;
    timeCost = 0;
    removedPrice = 0;
    addedPrice = 0;
    labourPrice = 0;
    // std = SHP;
    // otr = OTP;
    // tph = THP;
    //works on load of component.
    connectedCallback() {
        this.getProductListFromServer(this.searchKey, this.filter,true);
    }
    onAssemblyCreation(event){
        let recordId = event.detail.id;
        if(recordId){
            this.createAssemblyItems(recordId,this.productsToShow,this.itemsCount);
        }
    }
    handleSearchKeyChange(event){
        this.searchKey = event.target.value;
        let keyLength;
        if(!this.searchKey){
            keyLength = 0;
        }
        if(this.searchKey && this.searchKey.length>=2 ){
            this.getProductListFromServer(this.searchKey,this.filter,true);
        } else if(keyLength===0){
            this.getProductListFromServer(this.searchKey,this.filter,true);
        }
    }
    handleProductFitlerChange(event){
        this.filter = event.target.value;
        if(this.filter){
            this.getProductListFromServer(this.searchKey,this.filter,true);
        }
    }
    getProductListFromServer(searchKey,filter,isAssembly){
        let mapOfProducts = this.mapWithProductId;
        getProductData({
            searchKey: searchKey,
            filterOption: filter,
            isAssembly:isAssembly
        }).then((result)=>{
            //console.log('result of products = '+JSON.stringify(result));
            this.productList = result.map(function (element) {
                if(mapOfProducts && mapOfProducts.size>0){
                    if(mapOfProducts.has(element.Id)){
                        element.isSelected = mapOfProducts.get(element.Id);
                    }
                } else{
                    element.isSelected = false;
                }
                element.quantity = 0;
                element.margin = 0;
                element.salesPrice = 0;
                element.costPrice = 0;
                return element;
            });
        }).catch((error)=>{

        });
    }

    handleRowSelection(event){
        event.preventDefault();
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

    handleQtyMarginChange(event){
        let context= event.currentTarget.dataset.context
        let recordId = event.currentTarget.dataset.recordid;
        let value = event.target.value;
        let selectedArrayList = Array.from(this.mapWithProdIdProd.values());
        let elementsToPush= [];
        let costP = 0;
        let salesP = 0;
        selectedArrayList.filter(function(element){
            if(element.Id===recordId){
                if(context === 'quantity'){
                    element.quantity = value;
                } else if(context==='margin'){
                    element.margin = value;
                }
                let currentCost = (element.UnitPrice*element.quantity);
                element.costPrice = currentCost;
                element.salesPrice = currentCost+((element.margin/100)*(currentCost));
                console.log('data of cost price = '+element.costPrice+'_ sales price _ '+element.salesPrice);
            }
            return element;
        });
        if(selectedArrayList){
            selectedArrayList.forEach(function(element){
                elementsToPush.push({Id:element.Product2Id,UnitPrice:element.UnitPrice,quantity:element.quantity,margin:element.margin});
                costP = costP+element.costPrice;
                salesP = salesP + element.salesPrice;
                console.log('data of cost costP = '+costP+'_ sales salesP _ '+salesP);
                return element;
            });
            if(costP){
                this.itemCostPrice = costP;
                this.salesCostPrice = salesP;
            } else{
                this.itemCostPrice = 0;
                this.salesCostPrice = 0;
            }
        }
        if(elementsToPush.length>0){
            this.productsToShow = elementsToPush;
        }
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
        this.itemCostPrice = this.itemCostPrice - removedCost;
        this.salesCostPrice = this.salesCostPrice - removedSCost;
       
        if(existingDataMap && existingDataMap.size>0){
            this.mapWithProdIdProd = existingDataMap;
        }
        this.itemsCount = this.mapWithProdIdProd.size;
        if((this.salesCostPrice<=0 || this.salesCostPrice>0) && this.itemsCount<=0){
            if(this.salesCostPrice>0 && this.labourPrice){
                this.salesCostPrice = 0;
                this.setLabourCostToZero();
            }else if(this.salesCostPrice<=0 && this.labourPrice){
                this.setLabourCostToZero();
            }
        }
    }
    fireSuccessEvent(){
        this.dispatchEvent(new CustomEvent('success'));
    }
    fireFailureEvent(){
        this.dispatchEvent(new CustomEvent('failure'));
    }
    createAssemblyItems(recordId,elementsToSend,count){
        customProduct({assemblyId:recordId,bundleItems:JSON.stringify(elementsToSend),ItemsCount:count}).then((result)=>{
            console.log('result value = '+result);
        }).catch((error)=>{
            console.log('result value = '+error);
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
    handleUploadFinished(event){
        const uploadFiles = event.detail.files;
        if(uploadFiles.length>0){
            uploadFiles.forEach(element=>this.documentIdList.push(element.documentId));
        }
    }
    overrideCancel(event){
        this.fireFailureEvent();
    }
    onHourChange(event){
        let type = event.currentTarget.dataset.type;
        if(type==='SH'){
            this.standardHours = event.target.value;
            this.standardPrice = ((this.standardHours?this.standardHours:0)*(this.standardCost?this.standardCost:0));
            
        }else if(type==='OH'){
            this.overtimeHours = event.target.value;
            this.overtimePrice = ((this.overtimeHours?this.overtimeHours:0)*(this.overtimeCost?this.overtimeCost:0));
        }else if(type==='TH'){    
            this.timeAndHalfHours = event.target.value;
            this.timePrice = ((this.timeAndHalfHours?this.timeAndHalfHours:0)*(this.timeCost?this.timeCost:0));
        }
        this.labourPrice = this.standardPrice+this.overtimePrice+this.timePrice;
    }
    handleCostChange(event){
        let cost = event.currentTarget.dataset.cost;
        if(cost==='SC'){
            this.standardCost = event.target.value;
            this.standardPrice = ((this.standardHours?this.standardHours:0)*(this.standardCost?this.standardCost:0));
        }else if(cost==='OC'){
            this.overtimeCost = event.target.value;
            this.overtimePrice = ((this.overtimeHours?this.overtimeHours:0)*(this.overtimeCost?this.overtimeCost:0));
        }else if(cost==='TC'){
            this.timeCost = event.target.value;
            this.timePrice = ((this.timeAndHalfHours?this.timeAndHalfHours:0)*(this.timeCost?this.timeCost:0));
        } 
        this.labourPrice = this.standardPrice+this.overtimePrice+this.timePrice;
    }

    get labourCost(){
        return this.labourPrice;
    }

    get totalSalesPrice(){
        if(this.salesCostPrice && this.labourCost ){
            return (this.salesCostPrice+this.labourCost);
        }else if(this.salesCostPrice>0 && this.labourCost<=0 ){
            return this.salesCostPrice;
        }else if(this.salesCostPrice<=0){
           return 0;
        }
    }

    setLabourCostToZero(){
        this.standardPrice = 0;
        this.standardCost = 0;
        this.standardHours = 0;
        this.overtimePrice = 0;
        this.overtimeCost = 0;
        this.overtimeHours = 0;
        this.timePrice = 0;
        this.timeCost = 0;
        this.timeAndHalfHours = 0;
        this.labourPrice = 0;
    }
 
}