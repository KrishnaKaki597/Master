/**************************************************************************************************************
 * Class Name : AttachProductsToOpportunity
 * Create Date : 
 * Description : This class acts as a server class to lwc component for add products functionality.
 * Change log
 * ************************************************************************************************************
 * Original Version            Krishna kaki                             
***************************************************************************************************************/
public with sharing class AttachProductsToOpportunity {
    public static String prodBaseQuery;
    public Integer baseLimit;
    public static String filterQuery;
    public AttachProductsToOpportunity() {
       baseLimit = 10;
    }
    static{
        prodBaseQuery = 'SELECT Id,Name,ProductCode,Product2Id,UnitPrice,IsActive,priceBook2Id,Product2.Description,Product2.Type_Product__c,Product2.Vendor_Name__c FROM PriceBookEntry WHERE IsActive=true';
        filterQuery = ' ORDER BY CreatedDate DESC LIMIT 5';
    }
    /****************************************************************************************************
     @Method Name : getProductList
     @searchKey : search key entered from UI
     @filterOption : filter selected from UI
     @isAssembly : true if invoked from assembly screen else false.
     @return type : list of pricebook entries.
     @Description : to get product information on load/on search of products.
    *****************************************************************************************************/
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
    /****************************************************************************************************
     @Method Name : getOpptyLineItems
     @opptyId : opportunity id
     @return type : list of oppline item wrappers.
     @Description : to get existing opportunity products for an opportunity.
    *****************************************************************************************************/
    @AuraEnabled
    public static List<OppLineItemWrapper> getOpptyLineItems(String opptyId){ 
       List<OppLineItemWrapper> oppWrapperList = new List<OppLineItemWrapper>();
       Map<Id,OpportunityLineItem> mapPbEntryIdOpptyProd = new Map<Id,OpportunityLineItem>();
       for(OpportunityLineItem oppItem : [SELECT Id,Opportunity.Item_Cost_Price__c,Product2Id,PricebookEntryId,Quantity,Margin__c,UnitPrice,ListPrice,ProductCode,TotalPrice FROM OpportunityLineItem WHERE OpportunityId =: opptyId]){
            mapPbEntryIdOpptyProd.put(oppItem.Product2Id,oppItem);
       }
       for(PriceBookEntry objPBEntry : [SELECT Id,Name,ProductCode,Product2Id,UnitPrice,IsActive,priceBook2Id,Product2.Description,Product2.Type_Product__c,Product2.Vendor_Name__c FROM PriceBookEntry WHERE IsActive=true AND Product2Id IN : mapPbEntryIdOpptyProd.keySet() AND priceBook2Id=:getPriceBookId()]){
            if(mapPbEntryIdOpptyProd.containsKey(objPBEntry.Product2Id)){
                OppLineItemWrapper objOppProd = new OppLineItemWrapper();
                objOppProd.pbid = objPBEntry.Id;
                objOppProd.prdId = objPBEntry.Product2Id;
                objOppProd.prdName = objPBEntry.Name;
                objOppProd.vdrName = objPBEntry.Product2.Vendor_Name__c;
                objOppProd.prCode = objPBEntry.ProductCode;
                objOppProd.comment = objPBEntry.Product2.Description;
                OpportunityLineItem objLineItem = mapPbEntryIdOpptyProd.get(objPBEntry.Product2Id);
                objOppProd.prCost = objPBEntry.UnitPrice;
                objOppProd.totalCostPrice = objLineItem.Opportunity.Item_Cost_Price__c;
                //objOppProd.oppLineItemId = objLineItem.Id;
                objOppProd.prQty = (Integer)objLineItem.Quantity;
                objOppProd.prSalesCost = objLineItem.TotalPrice;
                objOppProd.prMargin = (Integer)objLineItem.Margin__c;
                oppWrapperList.add(objOppProd);
            }
       }  
       return oppWrapperList;
    }
    /****************************************************************************************************
     @Method Name : saveProductsToOpportunity
     @productsInContext : products information selected from UI.
     @parentId : opportunity id
     @Description : to save opportunity products to an opportunity.
    *****************************************************************************************************/
    @AuraEnabled
    public static string saveProductsToOpportunity(String productsInContext,String parentId){
        String responseFromServer;
        try {
               List<OpportunityLineItem> oppItemList = new List<OpportunityLineItem>();
               if(String.isNotBlank(productsInContext)){
                    List<OpportunityLineItem> oppLineItemToDelete = getOppLineItems(parentId);
                    List<PriceBookEntryWrapper> prodWrapperList = (List<PriceBookEntryWrapper>)JSON.deserialize(productsInContext,List<PriceBookEntryWrapper>.CLASS);
                    if(prodWrapperList.size()>0){
                        for(PriceBookEntryWrapper objProdWrap : prodWrapperList){
                            OpportunityLineItem objOppItem = new OpportunityLineItem(OpportunityId = parentId,
                            PricebookEntryId = objProdWrap.Id,TotalPrice = Integer.valueOf(objProdWrap.salesPrice),
                            Margin__c = Integer.valueOf(objProdWrap.margin),quantity = Integer.valueOf(objProdWrap.quantity));
                            oppItemList.add(objOppItem);
                        }
                        if(!oppLineItemToDelete.isEmpty()){
                            delete oppLineItemToDelete;
                        }
                        if(!oppItemList.isEmpty()){
                            insert oppItemList; 
                            responseFromServer = 'OK';
                        }
                    }
               }else{
                    List<OpportunityLineItem> oppLineItemToDelete = getOppLineItems(parentId);
                    if(!oppLineItemToDelete.isEmpty()){
                        delete oppLineItemToDelete;
                    }
                    responseFromServer = 'OK';
               }
            }
         catch (Exception e) {
            System.debug('some exception'+e.getMessage());
            responseFromServer = 'Failure';
        }
        return responseFromServer;
    }
    /****************************************************************************************************
     @Method Name : frameProductQuery
     @searchKey : search key from UI.
     @filterOption : filter option from UI.
     @proBaseQuery : base query required to complete the soql string.
     @filterQuery : filter part of query
     @pricebookId : pricebook id 
     @isAssembly : true if on assembly screen else false.
     @return type : framed soql string.
     @Description : method to frame final soql query.
    *****************************************************************************************************/
    private static string frameProductQuery(String searchKey,String filterOption,String prodBaseQuery,String filterQuery,Id priceBookId,Boolean isAssembly){
        String finalProductQuery = prodBaseQuery;
        String productFilterQueryStr = ' AND Product2.Type_Product__c IN ('+'\''+'Custom Product'+'\''+','+'\''+'Standard Product'+'\''+')';
        if(String.isNotBlank(searchKey) && String.isNotBlank(filterOption)){
                finalProductQuery = finalProductQuery+(!isAssembly?' AND ( ProductCode LIKE \'%'+searchKey+'%\''+' OR Name LIKE \'%'+searchKey+'%\''+' ) AND Product2.Type_Product__c ='+'\''+filterOption+'\'' +' AND priceBook2Id='+'\''+priceBookId+'\'':' AND ( ProductCode LIKE \'%'+searchKey+'%\''+' OR Name LIKE \'%'+searchKey+'%\''+' ) AND Product2.Vendor__c ='+'\''+filterOption+'\'' +' AND priceBook2Id='+'\''+priceBookId+'\'');
        } else if(String.isNotBlank(searchKey) && String.isBlank(filterOption) ){
            finalProductQuery = finalProductQuery+' AND ( ProductCode LIKE \'%'+searchKey+'%\''+' OR Name LIKE \'%'+searchKey+'%\''+' ) AND priceBook2Id='+'\''+priceBookId+'\'';
        } else if(String.isNotBlank(filterOption) && String.isBlank(searchKey) ){
            finalProductQuery = finalProductQuery+(!isAssembly?' AND Product2.Type_Product__c = '+'\''+filterOption+'\''+' AND priceBook2Id='+'\''+priceBookId+'\'':' AND Product2.Vendor__c = '+'\''+filterOption+'\''+' AND priceBook2Id='+'\''+priceBookId+'\'');
        } else{
            finalProductQuery = finalProductQuery+' AND priceBook2Id='+'\''+priceBookId+'\'';
        }
        finalProductQuery = finalProductQuery+(!isAssembly?'':productFilterQueryStr)+filterQuery;
        return finalProductQuery;
    }
    /****************************************************************************************************
     @Method Name : getProducts
     @queryToExecute : query to perform soql
     @return type : list of pricebook entries.
     @Description : method to get list of pricebooke entries.
    *****************************************************************************************************/
    private static List<PriceBookEntry> getProducts(String queryToExecute){
        List<PriceBookEntry> priceBookList = new List<PriceBookEntry>();
        priceBookList = Database.query(queryToExecute);
        return priceBookList;
    }
    /****************************************************************************************************
     @Method Name : getOppLineItems
     @oppId : opportunity id 
     @return type : list of opportunity line items.
     @Description : method to get existing opportunity line items.
    *****************************************************************************************************/
    public static List<OpportunityLineItem> getOppLineItems(String oppId){
        List<OpportunityLineItem> oppItemList = new List<OpportunityLineItem>([SELECT Id,Name,Product2Id,PriceBookEntryId,TotalPrice,UnitPrice,Quantity,ProductCode FROM OpportunityLineItem WHERE OpportunityId=:oppId]);
        return oppItemList;
    }
    /****************************************************************************************************
     @Method Name : getPriceBookId
     @return type : Id of pricebook required
     @Description : method to get pricebook id.
    *****************************************************************************************************/
    private static Id getPriceBookId(){
        return [SELECT Id,Name FROM PriceBook2 WHERE Name=:ConstantUtils.CUSTOM_SALES_PB AND IsActive = true ].Id;
    }
    /****************************************************************************************************
     @Method Name : getLineItems
     @assemblyId :  assembly id passed from UI.
     @return type : list of opportunity line item wrapper
     @Description : method to wrapper form of existing opportunity line itemdata.
    *****************************************************************************************************/
    @AuraEnabled
    public static List<OppLineItemWrapper> getLineItems(String assemblyId){
        List<OppLineItemWrapper> assmblyWrapperList = new List<OppLineItemWrapper>();
        Integer stHours = 0;
        Integer stCost = 0;
        Integer stPrice = 0;
        Integer overHours = 0;
        Integer overCost = 0;
        Integer overPrice = 0;
        Integer tHours = 0;
        Integer tPrice = 0;
        Integer tCost = 0;
        List<Assembly__c> assemblyList = new List<Assembly__c>();
        List<Assembly_Line_Items__c> assemblyItemList = new List<Assembly_Line_Items__c>();
        List<Product2> prodList = [SELECT Id,Name,ProductCode,Overtime_Cost__c,Overtime_Hours__c,Overtime_Price__c,Standard_Cost__c,Standard_Hours__c,Standard_Price__c,Time_Half_Cost__c,Time_and_Half_Hours__c,Time_And_Half_Price__c FROM Product2 WHERE Id=:assemblyId];
        Map<Id,String> mapProdIdWrapper = new Map<Id,String>();
        if(prodList.size()>0){
            Product2 objProd = prodList[0];
            assemblyList = [SELECT Id,Product_Name__c,Product_Code__c,Overtime_Cost__c,Overtime_Hours__c,Overtime_Price__c,Standard_Cost__c,Standard_Hours__c,Standard_Price__c,Time_And_Half_Cost__c,Time_and_Half_Hours__c,Time_And_Half_Price__c FROM Assembly__c WHERE Product_Code__c=:objProd.ProductCode];
            stHours = (Integer)objProd.Standard_Hours__c;
            stCost = (Integer)objProd.Standard_Cost__c;
            stPrice = (Integer)objProd.Standard_Price__c;
            overHours = (Integer)objProd.Overtime_Hours__c;
            overCost = (Integer)objProd.Overtime_Cost__c;
            overPrice = (Integer)objProd.Overtime_Price__c;
            tHours = (Integer)objProd.Time_and_Half_Hours__c;
            tPrice = (Integer)objProd.Time_And_Half_Price__c;
            tCost = (Integer)objProd.Time_Half_Cost__c;

            if(assemblyList.size()>0){
                OppLineItemWrapper objALItemWrapper;
                for(Assembly_Line_Items__c objALItem : [SELECT Id,Margin__c,Assembly__c,Assembly__r.Overtime_Cost__c,Assembly__r.Overtime_Hours__c,Assembly__r.Overtime_Price__c,Assembly__r.Standard_Cost__c,Assembly__r.Standard_Hours__c,Assembly__r.Standard_Price__c,Assembly__r.Time_And_Half_Cost__c,Assembly__r.Time_and_Half_Hours__c,Assembly__r.Time_And_Half_Price__c,Quantity__c,Product__c FROM Assembly_Line_Items__c WHERE Assembly__c =:AssemblyList[0].Id]){
                    mapProdIdWrapper.put(objALItem.Product__c,String.valueOf(objALItem.Margin__c+'::'+objALItem.Quantity__c));
                }
                for(PriceBookEntry objPBEntry : [SELECT Id,Name,ProductCode,Product2.Number_of_items__c,Product2.Cost__c,Product2Id,UnitPrice,IsActive,priceBook2Id,Product2.Description,Product2.Type_Product__c,Product2.Vendor_Name__c FROM PriceBookEntry WHERE IsActive = TRUE AND PriceBook2Id=:getPriceBookId() AND Product2Id IN : mapProdIdWrapper.keySet()]){
                    if(mapProdIdWrapper.containsKey(objPBEntry.Product2Id))
                    objALItemWrapper = new OppLineItemWrapper();
                    objALItemWrapper.prdId = objPBEntry.product2Id;
                    String qtyStr = mapProdIdWrapper.get(objPBEntry.Product2Id); 
                    objALItemWrapper.prMargin = Integer.valueOf(qtyStr.subStringBefore('::'));
                    objALItemWrapper.prQty = Integer.valueOf(qtyStr.subStringAfter('::'));
                    objALItemWrapper.pbid = objPBEntry.Id;
                    objALItemWrapper.prdName = objPBEntry.Name;
                    objALItemWrapper.vdrName = objPBEntry.Product2.Vendor_Name__c;
                    objALItemWrapper.prCode = objPBEntry.ProductCode;
                    objALItemWrapper.prCost = objPBEntry.UnitPrice;
                    objALItemWrapper.UnitPrice = objPBEntry.UnitPrice;
                    //objALItemWrapper.prSalesCost = (objPBEntry.UnitPrice*objALItemWrapper.prQty)+((objALItemWrapper.prMargin/100)*(objPBEntry.UnitPrice));
                    objALItemWrapper.stdHours = (stHours!=null?stHours:0);
                    objALItemWrapper.stdCost = (stCost!=null?stCost:0);
                    objALItemWrapper.stdPrice = (stPrice!=null?stPrice:0);
                    objALItemWrapper.otHours = (overHours!=null?overHours:0);
                    objALItemWrapper.otCost =  (overCost!=null?overCost:0);
                    objALItemWrapper.otPrice = (overPrice!=null?overPrice:0);
                    objALItemWrapper.thHours = (tHours!=null?tHours:0);
                    objALItemWrapper.thCost = (tCost!=null?tCost:0);
                    objALItemWrapper.thPrice = (tPrice!=null?tPrice:0);
                    assmblyWrapperList.add(objALItemWrapper);
                }
            }
        }
        return assmblyWrapperList;
    }

    public class PriceBookEntryWrapper{
        public String Id;
        public String quantity;
        public String margin;
        public Decimal salesPrice;
    }
    public class OppLineItemWrapper{
       @AuraEnabled
       public String pbid;
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
       public Integer prQty;
       @AuraEnabled
       public Integer prMargin;
       @AuraEnabled
       public Decimal UnitPrice;
       @AuraEnabled
       public Decimal totalCostPrice;
       @AuraEnabled
       public Integer stdHours;
       @AuraEnabled
       public Integer stdCost;
       @AuraEnabled
       public Integer stdPrice;
       @AuraEnabled
       public Integer otHours;
       @AuraEnabled
       public Integer otCost;
       @AuraEnabled
       public Integer otPrice;
       @AuraEnabled
       public Integer thHours;
       @AuraEnabled
       public Integer thCost;
       @AuraEnabled
       public Integer thPrice;

    }
    
}