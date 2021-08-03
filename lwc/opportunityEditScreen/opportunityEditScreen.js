import { LightningElement,api } from 'lwc';
export default class OpportunityEditScreen extends LightningElement {
     objectAPIName = 'Opportunity';
     @api recordId;
     connectedCallback(){}
     updateOpportunity(event){
          this.overrideCancel(event);
     }
     overrideCancel(event){
          this.dispatchEvent(new CustomEvent('close'));
     }

}