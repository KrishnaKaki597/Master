import { LightningElement } from 'lwc';
import recentOpportunities from '@salesforce/apex/ProductBuilderController.getRecentOpportunities';
export default class ProductBuilderCmp extends LightningElement {
     activeTabValue='Opportunity';
}