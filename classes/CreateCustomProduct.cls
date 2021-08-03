/****************************************************************************************************
 * Class name : CreateCustomProduct
 * Created by : 
 * Created date : 
 * Description : This class serves as server side controller for LWC Component dealing with custom product
****************************************************************************************************/
public with sharing class CreateCustomProduct {
    /***************************************************************************************
      @method name : createAssemblyLineItems
      @assemblyId : id of the assembly record created.
      @bundleItems : json of selected assembly line items.
      @itemCount : count of assembly line items.
      @return type : response on success and failure
      @description : to create assembly line items selected from UI.
    ****************************************************************************************/
    @AuraEnabled
    public static string createAssemblyLineItems(String assemblyId,String bundleItems,Integer ItemsCount){
        List<Assembly_Line_Items__c> assemblyItemsToCreate = new List<Assembly_Line_Items__c>();
        String response = '';
        try{
            if(ItemsCount>0){
                List<AssemblyWrapper> assemblyItemsList = (List<AssemblyWrapper>)JSON.deserialize(bundleItems,List<AssemblyWrapper>.CLASS);
                if(assemblyItemsList.size()>0){
                    Integer count = 1;
                    for(AssemblyWrapper objAssembly : assemblyItemsList){
                        Assembly_Line_Items__c objAssemblyItem = new Assembly_Line_Items__c();
                        objAssemblyItem.Quantity__c = objAssembly.quantity;
                        objAssemblyItem.Margin__c = objAssembly.margin;
                        objAssemblyItem.List_Price__c = objAssembly.UnitPrice;
                        objAssemblyItem.Assembly__c = assemblyId;
                        objAssemblyItem.Product__c = objAssembly.Id;
                        objAssemblyItem.Order__c = count;
                        assemblyItemsToCreate.add(objAssemblyItem);
                        count++;
                    }
                }
            }
            if(!assemblyItemsToCreate.isEmpty() && assemblyItemsToCreate.size()>0){
                insert assemblyItemsToCreate;
                createBundledProduct(assemblyId);
                response = '200';
            }
        } catch (Exception exp){
            System.debug('Exception messages ='+exp.getMessage());
            response = '400';
        }      
        return response;
    }
    /***************************************************************************************
      @method name : createPriceBooksEntry
      @productId : id of the product thats being created.
      @unitCost : unit cost for product
      @return type : response on success and failure
      @description : to create price book entries for product
    ****************************************************************************************/
    @AuraEnabled
    public static string createPriceBooksEntry(String productId,Decimal unitCost){
        try{
            Id standardPriceBookdId = [SELECT Id FROM PriceBook2 WHERE Name=:ConstantUtils.STD_PB AND IsActive=true ].Id;
            Id opportunitySalesPBId = [SELECT Id FROM PriceBook2 WHERE Name=:ConstantUtils.CUSTOM_SALES_PB AND IsActive=true ].Id;
            PriceBookEntry objStdPBEntry = new PriceBookEntry();
            objStdPBEntry.Product2Id = Id.valueOf(productId);
            objStdPBEntry.Pricebook2Id = standardPriceBookdId;
            objStdPBEntry.UnitPrice = unitCost;
            objStdPBEntry.IsActive = true;
            insert objStdPBEntry;
            PriceBookEntry objCustomPBEntry = new PriceBookEntry();
            objCustomPBEntry.Product2Id=Id.valueOf(productId);
            objCustomPBEntry.Pricebook2Id=opportunitySalesPBId;
            objCustomPBEntry.UnitPrice=unitCost;
            objCustomPBEntry.IsActive=true;
            insert objCustomPBEntry;
            return '200';
        } catch(Exception exp){
            return '400';
        }
    }
    /***************************************************************************************
      @method name : attachContentToProduct
      @contentList : content document id from UI.
      @productId : product id for which document has to be attached.
      @return type : response on success and failure
      @description : to create content version/documents to product.
    ****************************************************************************************/
    @AuraEnabled
    public static string attachContentToProduct(List<String> contentList,String productId){
        try {
            List<ContentDocumentLink> contentDocLink = new List<ContentDocumentLink>();
            List<ContentDocument> contentDocList = [SELECT Id,ParentId FROM ContentDocument WHERE Id IN:contentList];
            if(contentDocList.size()>0){
                for(ContentDocument objContentDoc : contentDocList){
                    ContentDocumentLink cDe = new ContentDocumentLink();
                    cDe.ContentDocumentId = objContentDoc.Id;
                    cDe.LinkedEntityId = productId;
                    cDe.ShareType = 'I';
                    cDe.Visibility = 'AllUsers';
                    contentDocLink.add(cDe);
                }
                insert contentDocLink;
            }
            return 'Ok';
        } catch (Exception exp) {
           return exp.getMessage();
        }
    }
    /***************************************************************************************
      @method name : createBundledProduct
      @assemblyId : assembly id which creates product
      @return type : none
      @description : to create assembly product.
    ****************************************************************************************/
    public static void createBundledProduct(Id assemblyId){
        Id standardPriceBookdId = [SELECT Id FROM PriceBook2 WHERE Name=:ConstantUtils.STD_PB AND IsActive=true ].Id;
        Id opportunitySalesPBId = [SELECT Id FROM PriceBook2 WHERE Name=:ConstantUtils.CUSTOM_SALES_PB AND IsActive=true ].Id;
        List<Assembly__c> objAssemblyList = [SELECT Id,Active__c,Standard_Cost__c,Standard_Hours__c,Standard_Price__c,Time_And_Half_Cost__c,Time_and_Half_Hours__c,Time_And_Half_Price__c,Overtime_Cost__c,Overtime_Hours__c,Overtime_Price__c,Product_Name__c,Number_Of_items__c,Product_Type__c,Product_Code__c,Cost__c,Description__c FROM Assembly__c WHERE Id=:assemblyId];
        if(objAssemblyList.size()>0){
            Product2 objProduct = new Product2();
            objProduct.Name = objAssemblyList[0].Product_Name__c;
            objProduct.Cost__c = objAssemblyList[0].Cost__c;
            objProduct.Number_of_items__c = objAssemblyList[0].Number_Of_items__c;
            objProduct.Type_Product__c = /*objAssemblyList[0].Product_Type__c.trim()*/'Assembly';
            objProduct.ProductCode = objAssemblyList[0].Product_Code__c;
            objProduct.IsActive = objAssemblyList[0].Active__c;
            objProduct.Overtime_Cost__c = objAssemblyList[0].Overtime_Cost__c!=null?objAssemblyList[0].Overtime_Cost__c:0;
            objProduct.Overtime_Hours__c = objAssemblyList[0].Overtime_Hours__c!=null?objAssemblyList[0].Overtime_Hours__c:0;
            objProduct.Overtime_Price__c =  objAssemblyList[0].Overtime_Price__c!=null?objAssemblyList[0].Overtime_Price__c:0;
            objProduct.Standard_Cost__c = objAssemblyList[0].Standard_Cost__c!=null?objAssemblyList[0].Standard_Cost__c:0;
            objProduct.Standard_Hours__c = objAssemblyList[0].Standard_Hours__c!=null? objAssemblyList[0].Standard_Hours__c:0;
            objProduct.Standard_Price__c = objAssemblyList[0].Standard_Price__c!=null?objAssemblyList[0].Standard_Price__c:0;
            objProduct.Time_and_Half_Hours__c = objAssemblyList[0].Time_and_Half_Hours__c!=null?objAssemblyList[0].Time_and_Half_Hours__c:0;
            objProduct.Time_and_Half_Price__c = objAssemblyList[0].Time_And_Half_Price__c!=null?objAssemblyList[0].Time_And_Half_Price__c:0;
            objProduct.Time_Half_Cost__c = objAssemblyList[0].Time_And_Half_Cost__c!=null?objAssemblyList[0].Time_And_Half_Cost__c:0;
            insert objProduct;
            PriceBookEntry objStdPBEntry = new PriceBookEntry();
            objStdPBEntry.Product2Id = objProduct.Id;
            objStdPBEntry.Pricebook2Id = standardPriceBookdId;
            objStdPBEntry.UnitPrice = objProduct.Cost__c;
            objStdPBEntry.IsActive = true;
            insert objStdPBEntry;
            PriceBookEntry objCustomPBEntry = new PriceBookEntry();
            objCustomPBEntry.Product2Id= objProduct.Id;
            objCustomPBEntry.Pricebook2Id=opportunitySalesPBId;
            objCustomPBEntry.UnitPrice=objProduct.Cost__c;
            objCustomPBEntry.IsActive=true;
            insert objCustomPBEntry;
        }
    }
    /***************************************************************************************
      @method name : getAssemblyItems
      @prodId : to get assembly items of assembly.
      @return type : list of assembly line items.
      @description : to get associated line items of an assembly.
    ****************************************************************************************/
    @AuraEnabled
    public static List<Assembly_Line_Items__c> getAssemblyItems(String prodId){
        List<Assembly_Line_Items__c> assemblyItems = new List<Assembly_Line_Items__c>();
        List<Product2> objProdList = [SELECT Id,Name FROM Product2 WHERE Id=:prodId];
        if(objProdList.size()>0){
            Assembly__c objAssembly = [SELECT Id,Name,Product_name__c FROM Assembly__c WHERE Product_name__c=:objProdList[0].Name];
            if(objAssembly!=null){
                assemblyItems = [SELECT Id,Name,Cost__c,Product__r.Type_Product__c,Product__r.IsActive,Product__r.Cost__c,Product__r.Name,Product__r.ProductCode,Product__r.Vendor__r.Name FROM Assembly_Line_Items__c WHERE Assembly__c=:objAssembly.Id];
            }
        }
        return assemblyItems;
    }
     /***************************************************************************************
      @method name : deleteExAssemblyItems
      @assemblyId : id of assembly
      @return type : none.
      @description : to get associated line items of an assembly.
    ****************************************************************************************/
    public static void deleteExAssemblyItems(String assemblyId){
        List<Assembly_Line_Items__c> delAssemblyItemList = [SELECT Id,Assembly__c FROM Assembly_Line_Items__c WHERE Assembly__c=:assemblyId];
        delete delAssemblyItemList;
    }
    @AuraEnabled
    public static string upsertExistingAssembly(String assemblyId,String bundleItems,Integer itemsCount){
       // System.assert(false,'data of items getting updated = '+assemblyId+' bundleItems = '+bundleItems+' itemsCount = '+itemsCount);
        List<Assembly_Line_Items__c> assemblyItemsToCreate = new List<Assembly_Line_Items__c>();
        Id opportunitySalesPBId = [SELECT Id FROM PriceBook2 WHERE Name=:ConstantUtils.CUSTOM_SALES_PB AND IsActive=true ].Id;
        String response;
        try{
            List<Product2> prod2List = [SELECT Id,Name,ProductCode,Cost__c FROM Product2 WHERE Id=:assemblyId];
           // System.assert(false,'data of prod2List = '+prod2List);
            List<PriceBookEntry> pbEntryList = [SELECT Id,Name,Product2Id,UnitPrice FROM PriceBookEntry WHERE PriceBook2Id=:opportunitySalesPBId AND Product2Id=:prod2List[0].Id];
           // System.assert(false,'data of pbEntryList = '+pbEntryList);
            List<Assembly__c> assemblyList = [SELECT Id,Name,Product_code__c FROM Assembly__c WHERE Product_code__c=:prod2List[0].ProductCode];
            
            deleteExAssemblyItems(assemblyList[0].Id);
            if(itemsCount>0){
                List<AssemblyWrapper> assemblyItemsList = (List<AssemblyWrapper>)JSON.deserialize(bundleItems,List<AssemblyWrapper>.CLASS);
                if(assemblyItemsList.size()>0){
                    Integer count = 1;
                    for(AssemblyWrapper objAssembly : assemblyItemsList){
                        Assembly_Line_Items__c objAssemblyItem = new Assembly_Line_Items__c();
                        objAssemblyItem.Quantity__c = objAssembly.quantity;
                        objAssemblyItem.Margin__c = objAssembly.margin;
                        objAssemblyItem.List_Price__c = objAssembly.UnitPrice;
                        objAssemblyItem.Assembly__c = assemblyList[0].Id;
                        objAssemblyItem.Product__c = objAssembly.Id;
                        objAssemblyItem.Order__c = count;
                        assemblyItemsToCreate.add(objAssemblyItem);
                        count++;
                    }
                }
            }
            if(!assemblyItemsToCreate.isEmpty() && assemblyItemsToCreate.size()>0){
                insert assemblyItemsToCreate;
                if(pbEntryList.size()>0){
                    PriceBookEntry objPBEntry = new PriceBookEntry();
                    objPBEntry.Id = pbEntryList[0].Id;
                    objPBEntry.UnitPrice = prod2List[0].Cost__c;
                    update objPBEntry;
                }
                response = '200';
            }
            
        }catch(Exception exp){
            response = '400';
        }
        return response;
    }
    public class AssemblyWrapper{
        public String Id;
        public Decimal UnitPrice;
        public Integer quantity;
        public Integer margin;
    }

    

}