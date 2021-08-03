import { LightningElement,api} from 'lwc';
export default class ProductEditScreen extends LightningElement {
     objectAPIName = 'Product2';
     @api recordId; 
     @api isCustomScreen;
     @api isAssetScreen;
     connectedCallback(){
     }
     updateProduct(event){
          this.overrideCancel(event);
     }
     overrideCancel(event){
          this.dispatchEvent(new CustomEvent('close'));
     }
}