public class OppInfo {
    @AuraEnabled public String OpportunityName;
    @AuraEnabled public String OpportunityDescription;
    @AuraEnabled public String OpportinityCloseDate;
    @AuraEnabled public String OpportunityStage;
    @AuraEnabled public ID AccountID;
    @AuraEnabled public ID OpportunityID;
    @AuraEnabled public decimal OpportunityAmount;
    @AuraEnabled public ID ContractID;
    @AuraEnabled public ID PricebookID;
}