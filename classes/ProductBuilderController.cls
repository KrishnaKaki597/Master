public with sharing class ProductBuilderController {
    public static Integer baseLimit = 10;
    public static String prodBaseQuery;
    public static String filterQuery;
    static{
        prodBaseQuery = 'SELECT Id,Name,ProductCode,Product2.Number_of_items__c,Product2.Cost__c,Product2Id,UnitPrice,IsActive,priceBook2Id,Product2.Description,Product2.Type_Product__c,Product2.Vendor_Name__c FROM PriceBookEntry WHERE IsActive=true';
        filterQuery = ' ORDER BY CreatedDate DESC LIMIT 5';
    }
    @AuraEnabled
    public static List<Opportunity> getRecentOpportunities(){
        return [SELECT Id,Name,Account.Name,Amount,CloseDate,StageName,CostCenter__c FROM Opportunity ORDER BY CreatedDate DESC Limit:baseLimit];
    }
    @AuraEnabled
    public static List<PriceBookEntry> getRecentAssets(){
        try {
            return [SELECT Id,Name,ProductCode,Product2Id,UnitPrice,IsActive,priceBook2Id,Product2.Description,Product2.QuantityUnitOfMeasure FROM PriceBookEntry WHERE IsActive=true AND Product2.Type_Product__c='Asset' AND priceBook2Id=:getPriceBookId() ORDER BY CreatedDate DESC LIMIT:baseLimit];
        } catch (Exception e) {
            return new List<PriceBookEntry>();
        }
    }
    @AuraEnabled
    public static List<PriceBookEntry> getProductList(String searchKey,String filterOption,Boolean isAssembly){
        List<PriceBookEntry> priceBookEntryList = new List<PriceBookEntry>();
        try{
            Id priceBookId = getPriceBookId();
            String prodQueryToExecute = frameProductQuery(searchKey,filterOption,prodBaseQuery,filterQuery,priceBookId,isAssembly);
            System.debug('query to execute = '+prodQueryToExecute);
            priceBookEntryList = getProducts(prodQueryToExecute);
            return priceBookEntryList;
        } catch(Exception exp){
            return priceBookEntryList;
        }
    }   
    @AuraEnabled(cacheable=true)
        public static String getContentDocumentId(String recordId) {
            // Get record file IDs        
            List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            return (files.size()>0?files[0].ContentDocumentId:'');
    }
    private static string frameProductQuery(String searchKey,String filterOption,String prodBaseQuery,String filterQuery,Id priceBookId,Boolean isAssembly){
        String finalProductQuery = prodBaseQuery;
        String productFilterQueryStr = (!isAssembly?' AND Product2.Type_Product__c IN ('+'\''+'Custom Product'+'\''+','+'\''+'Standard Product'+'\''+')':' AND Product2.Type_Product__c='+'\''+'Assembly'+'\'');
        if(String.isNotBlank(searchKey) && String.isNotBlank(filterOption)){
                finalProductQuery = finalProductQuery+(!isAssembly?' AND ( ProductCode LIKE \'%'+searchKey+'%\''+' OR Name LIKE \'%'+searchKey+'%\''+' ) AND Product2.Type_Product__c ='+'\''+filterOption+'\'' +' AND priceBook2Id='+'\''+priceBookId+'\'':' AND ( ProductCode LIKE \'%'+searchKey+'%\''+' OR Name LIKE \'%'+searchKey+'%\''+' ) AND Product2.Vendor__c ='+'\''+filterOption+'\'' +' AND priceBook2Id='+'\''+priceBookId+'\'');
        } else if(String.isNotBlank(searchKey) && String.isBlank(filterOption) ){
            finalProductQuery = finalProductQuery+' AND ( ProductCode LIKE \'%'+searchKey+'%\''+' OR Name LIKE \'%'+searchKey+'%\''+' ) AND priceBook2Id='+'\''+priceBookId+'\'';
        } else if(String.isNotBlank(filterOption) && String.isBlank(searchKey) ){
            finalProductQuery = finalProductQuery+(!isAssembly?' AND Product2.Type_Product__c = '+'\''+filterOption+'\''+' AND priceBook2Id='+'\''+priceBookId+'\'':' AND Product2.Vendor__c = '+'\''+filterOption+'\''+' AND priceBook2Id='+'\''+priceBookId+'\'');
        } else{
            finalProductQuery = finalProductQuery+' AND priceBook2Id='+'\''+priceBookId+'\'';
        }
        finalProductQuery = finalProductQuery+(String.isBlank(filterOption)?productFilterQueryStr:'')+filterQuery;
        return finalProductQuery;
    }
    private static List<PriceBookEntry> getProducts(String queryToExecute){
        List<PriceBookEntry> priceBookList = new List<PriceBookEntry>();
        priceBookList = Database.query(queryToExecute);
        return priceBookList;
    }
    private static Id getPriceBookId(){
        return [SELECT Id,Name FROM PriceBook2 WHERE Name=:ConstantUtils.CUSTOM_SALES_PB AND IsActive = true ].Id;
    }

    @AuraEnabled
    public static List<AssemblyItemWrapper> getAssemblyLinteItems(String assemblyId){
        try {
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return null;
    }
    public class AssemblyItemWrapper{
        @AuraEnabled
        public String pbId;
        @AuraEnabled
        public String prdId;
        @AuraEnabled
        public String prdName;
        @AuraEnabled
        public String vdrName;
        @AuraEnabled
        public String prCode;
        @AuraEnabled
        public String comment;
        @AuraEnabled
        public Decimal prCost;
        @AuraEnabled
        public Decimal prSalesCost;
        @AuraEnabled
        public Decimal prQty;
        @AuraEnabled
        public Decimal prMargin;
        @AuraEnabled
        public Decimal UnitPrice;
        @AuraEnabled
        public Decimal totalCostPrice;
    }

}