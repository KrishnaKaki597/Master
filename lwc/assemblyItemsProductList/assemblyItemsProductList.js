import { LightningElement,api } from 'lwc';
import assembledItems from '@salesforce/apex/CreateCustomProduct.getAssemblyItems';
export default class AssemblyItemsProductList extends LightningElement {
     @api
     recordId;
     assemblyItemsList = [];
     connectedCallback(){
          this.getLineItems();
     }
     getLineItems(){
          assembledItems({prodId:this.recordId}).then((result)=>{
               console.log('data from backend = '+JSON.stringify(result));
               this.assemblyItemsList = result.map(function(element){
                    element.Name = element.Product__r.Name;
                    element.Code = element.Product__r.ProductCode;
                    element.Cost = element.Product__r.Cost__c;
                    element.Type = element.Product__r.Type_Product__c;
                    element.IsActive = element.Product__r.IsActive;
                    return element;
               });
          }).catch((error)=>{

          });
     }
}