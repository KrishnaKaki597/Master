public class ProdBuild {
    
	@AuraEnabled public String ProductName;
    @AuraEnabled public String ProductDescription;
    @AuraEnabled public String PartNumber;
    @AuraEnabled public decimal Quantity;
    @AuraEnabled public decimal HoursRegular;
    @AuraEnabled public decimal HoursOverT;
    @AuraEnabled public decimal HoursTandH;
    @AuraEnabled public string ProdType;
    @AuraEnabled public string Vendor;
    @AuraEnabled public decimal Cost;
    @AuraEnabled public ID RecordId;
    @AuraEnabled public string Instructions;
    @AuraEnabled public ID PriceBookItem;
    @AuraEnabled public ID ProductCatItem;
}