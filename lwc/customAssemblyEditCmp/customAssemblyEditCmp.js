import { LightningElement,api,track} from 'lwc';
import getProductData from '@salesforce/apex/AttachProductsToOpportunity.getProductList';
import assemblyItems from '@salesforce/apex/AttachProductsToOpportunity.getLineItems';
import upsertLineItems from '@salesforce/apex/CreateCustomProduct.upsertExistingAssembly';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CustomAssemblyEditCmp extends LightningElement {
     @api recordId;
     objectApiName = 'Product2';
     @track productList = [];
     searchKey = null;
     filter = null;
     isEdit = false;
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
     connectedCallback(){
          this.getProductListFromServer(this.searchKey, this.filter,true);
     }
     onAssemblyCreation(event){
        this.updateAsssemblyItems(this.recordId,this.productsToShow,this.itemsCount);
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
          let localProductData = new Map();
          let scost = 0;
          let tcost = 0;
          let sh = 0;
          let sc = 0;
          let sp = 0;
          let oh = 0;
          let oc = 0;
          let op = 0;
          let th = 0;
          let tc = 0;
          let tp = 0;

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
          }).catch((error)=>{

          });
          if(!this.isEdit){
            assemblyItems({assemblyId:this.recordId}).then((result)=>{
                result.forEach(function(element){
                    element.Id = element.pbid;
                    element.isSelected = true;
                    element.prodId = element.prdId;
                    element.prodName = element.prdName;
                    element.vendorName = element.vdrName;
                    element.UnitPrice = element.UnitPrice;
                    element.quantity = element.prQty;
                    element.margin = element.prMargin;
                    element.salesPricet = ((element.UnitPrice*element.prQty)+((element.prMargin/100)*(element.UnitPrice)));
                    element.costPrice = element.UnitPrice;
                    element.salesPrice = element.salesPricet;
                    scost = scost+element.costPrice;
                    tcost = tcost+element.salesPrice;
                    sh = element.stdHours;
                    sc = element.stdCost;
                    sp = element.stdPrice;
                    oh = element.otHours;
                    oc = element.otCost;
                    op = element.otPrice;
                    th = element.thHours;
                    tc = element.thCost;
                    tp = element.thPrice;
                    localProductData.set(element.Id,element);
                });
                if(localProductData){
                    this.isEdit = true;
                    this.mapWithProdIdProd = localProductData;
                    //alert('data of items count = '+localProductData.size);
                    this.itemsCount = localProductData.size;
                    this.standardHours = sh;
                    this.standardCost = sc;
                    this.standardPrice = sp;
                    this.overtimeCost = oc;
                    this.overtimePrice = op;
                    this.overtimeHours = oh;
                    this.timeAndHalfHours = th;
                    this.timeCost = tc;
                    this.timePrice = tp;
                    alert('data of salesCost = '+tc + '>>>'+tp);
                    //alert('data of sp+op+tp = '+sp+'op ->'+op+' tp -->'+tp);
                    this.labourPrice = sp+op+tp;
                    this.salesCostPrice = tcost;
                    this.itemCostPrice = scost;
                }
              }).catch((error)=>{});
          }
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
          console.log('context = '+context+' recordId = '+recordId);
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
                  //alert('value of element.Product2Id = '+element.prodId);
                  elementsToPush.push({Id:element.prodId,UnitPrice:element.UnitPrice,quantity:element.quantity,margin:element.margin});
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
      get prodListToShow(){
          let mapOfProductsInCart = this.mapWithProdIdProd;
          let currentProdList = [];
          currentProdList = Array.from(mapOfProductsInCart.values());
          console.log('elements from current prodList = '+currentProdList);
          return currentProdList;
      }

      get totalSalesPrice(){
        if(this.salesCostPrice && this.labourPrice ){
            return (this.salesCostPrice+this.labourPrice);
        }else if(this.salesCostPrice>0 && this.labourPrice<=0 ){
            return this.salesCostPrice;
        }else if(this.salesCostPrice<=0){
           return 0;
        }
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
      updateAsssemblyItems(recordId,elementsToSend,count){
        upsertLineItems({assemblyId:recordId,bundleItems:JSON.stringify(elementsToSend),itemsCount:count}).then((result)=>{
            this.onSuccessToast();
            this.fireFailureEvent();
        }).catch((error)=>{
            console.log('result value = '+error);
        });
    }
      deleteLineItem(event){
        let prodInCartSize = this.mapWithProdIdProd.size;
        let commonMap = new Map();
        let recordId = event.currentTarget.dataset.recordid;
        let elementToRemove;
        let costToRemove = 0;
        this.mapWithProdIdProd.forEach((value,key)=>{
            if(key!==recordId){
                commonMap.set(key,value);
            }
            if(key===recordId){
                elementToRemove = value;
                costToRemove = elementToRemove.costPrice;
                console.log('price of cost to remove = '+costToRemove);
            }
        });
        if(costToRemove){
            if(costToRemove<this.itemCostPrice){
                this.itemCostPrice = this.itemCostPrice - costToRemove;
            }
        }
        this.mapWithProdIdProd = commonMap;
    } 
     overrideCancel(event){
          this.fireFailureEvent();
     }
     fireFailureEvent(){
          this.dispatchEvent(new CustomEvent('failure'));
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
}