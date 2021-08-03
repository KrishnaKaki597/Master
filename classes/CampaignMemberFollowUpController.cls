//  Copyright (c) 2009, Steffen Kuprat, Sales Engineering, Salesforce.com Inc.
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//    1.    Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 
//    2.    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the
//          documentation and/or other materials provided with the distribution.
//    3.    Neither the name of the salesforce.com nor the names of its contributors may be used to endorse or promote products derived from this
//          software without specific prior written permission. 
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
//  INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


public class CampaignMemberFollowUpController {
    // get get campaign status picklist values
    static Schema.DescribeFieldResult F = Campaign.Status.getDescribe();
	static List<Schema.PicklistEntry> P = F.getPicklistValues();  
    
    //init with first campaign picklist value
    private String SelectedStatus = P[0].getValue();
    
    //checks if Owner Id is User Id
    static Schema.DescribeSObjectResult su = User.sObjectType.getDescribe();
    private String UserKeyPrefix = su.getKeyPrefix();
    
    private String StatusTask; 
    public String SelectedCampaign {get; set;}
    public boolean showCampaignSelection {get; set;}
    //pageMessage
    public String pageMessageTitle {get; set;}
    public String pageMessageDetail {get; set;}
    public String pageMessageSeverity {get; set;}
    public Integer pageMessageStrength {get; set;}
    public boolean showPageMessage {get; set;}
    //public boolean showCMTable {get; set;}
    public boolean showtask {get; set;}
    public boolean CMOwner {get; set;}
    public boolean allCMselected {get; set;}
    public boolean showSelectButton {get; set;}
    // error message status if 'Create Follow Up' Button was pushed without selected CMembers
    public boolean showFollowUpButtonMessage {get; set;}
    //whole query CM list
    List<MyCampaignMember> CMemberList = new List<MyCampaignMember>();
    //all CM list with no valid user for task creation
    List<MyCampaignMember> BadCMemberList = new List<MyCampaignMember>();
    // CM list for the current page
    List<MyCampaignMember> CMemberListNext = new List<MyCampaignMember>();
    //list of all Tasks to be created
    List<Task> OwnerTodoList = new List<Task>();
    //prefilled Value to display in Follow Up Section
    Task OwnerTodo = new Task();
    Map<String,String> CampaignOwner = new Map<String,String>{};
    Map<String, boolean> SelectedCM = new Map<String, boolean>{};
    //for Paging: set 'next' and 'count' to the number of your paging size,
    //default 25,
    //both should have the same value
   	Integer next = 25, count = 25;
    boolean shownext, showprev = false;
    //helper for coping CMemberListNext.checkedMember status back to CMemberList.checkedMember 
    Integer copydownlimit;
    public boolean getshownext(){return shownext;}
    public boolean getshowprev(){return showprev;} 
    //checkbox per page
    private boolean allCheckboxes = false;
    
    //V1.1
    String myquery;
    public List<MyCampaignMember> getBadCMemberList(){
    	return BadCMemberList;
    }
    public PageReference showList(){
    	PageReference apexRef = new PageReference('/apex/Excel_list');
    	return apexRef;
    }
    
    //get and set for allCheckboxes only used from message
    public boolean getallCheckboxes(){
    	return allCheckboxes;
    }
    public void setallCheckboxes(boolean allCheckboxes){}
    
    public void changeCheckbox(){
    	if(allCheckboxes){
    		allCheckboxes = false;
    	}else{
    		allCheckboxes = true;
    	}
    	CheckboxValue(allCheckboxes);
    	copyList();
    }
    
    public void changeSingleCheckbox(){copyList();}
    
    public Integer getSelectedCM() {return SelectedCM.size();}
    
    //Multiselect checkbox
    public void CheckboxValue(boolean cb){
    	Integer j;
    	if(CMemberListNext.size()<count){
    		j = CMemberListNext.size();
    	}else{
    		j=count;
    	}
    	for(Integer i=0; i<j; i++) {
        	if(cb == true){
                CMemberListNext[i].checkedMember = true;
        	} else {
                CMemberListNext[i].checkedMember = false;
        	}
    	}
    }
    
    public void selectAllCMembers(){
    	if( allCMselected){
    		allCMselected = false;
    	}else{
    		allCMselected = true;
    	}
    	for(Integer i=0;i<CMemberList.size();i++){
            CMemberList[i].checkedMember = allCMselected;
        	if( allCMselected){
        		SelectedCM.put(CMemberList.get(i).Id, CMemberList.get(i).checkedMember);
        		}else{
        		SelectedCM.remove(CMemberList.get(i).Id);	
        	}	
        	CheckboxValue(allCMselected);
		}   
    }
        
    public List<MyCampaignMember> getCMemberListNext(){
    	return CMemberListNext;
    }
    public void setCMemberListNext(List<MyCampaignMember> CMemberListNext){
    	this.CMemberListNext = CMemberListNext;
    }
    
    //Controller Constructor checks for campagin id query parameter and shows 
    public CampaignMemberFollowUpController(){
    	 String stringcid = ApexPages.currentPage().getParameters().get('Id');
    	 Schema.DescribeSObjectResult cr = Campaign.sObjectType.getDescribe();
    	if(stringcid != null && stringcid != ''){
			if((stringcid.substring(0,3)== cr.getKeyPrefix()) && (stringcid.length()==18 ||stringcid.length()==15)){	
					try{
						Campaign camp = [SELECT ownerId, Id FROM Campaign WHERE Id =:stringcid];
						if(camp != null){
							System.debug('campaign : '+camp);
							CampaignOwner.put(camp.Id, camp.ownerId);
							SelectedCampaign = camp.Id;
							showCampaignSelection = false;
							renderFollowUpTrue();
						}
					}catch (Exception e){
					System.debug('no campaign found or no valid format');
					showCampaignSelection = true;
					}
			}else{
			System.debug('query param is not a valid campagin id');
			showCampaignSelection = true;	
			}
    	}else{
    	 System.debug('no query parameter for id');
    	 showTask = false;
		 showCampaignSelection = true;
    	}
    	
    	showFollowUpButtonMessage = false;
    	
    	allCMselected = false;
    	CMOwner = true;
    	selectedFilterStatus = startFilterStatus;
    	//selectedFilterType = 'Both';
    	myquery = 'default';
    }
    // campaign member wrapper class
    public class MyCampaignMember {
    	public String Id {get; set;}
    	public String FirstName {get; set;}
    	public String LastName {get; set;}
    	public String CMType {get; set;}
    	public String Email {get; set;}
    	public String Employer {get; set;}
    	public String City {get; set;}
    	public String Status {get; set;}
    	public String OwnerId {get; set;}
    	public boolean checkedMember{get; set;}
    	public String WhoId {get; set;}
    	public Integer NumberOfEmployees {get; set;}
    	public String Title {get; set;}
    	public String ZipCode {get; set;}
    	public boolean OwnerIsActive {get; set;}
    	public MyCampaignMember() {
    		checkedMember = false;
    	}
    }
    
    //helpers for FollowUp Page Block
    public void renderFollowUpTrue() {
    	showtask = true;
    	OwnerTodo.clear();
    	myquery = 'default';
    	
    	loadCampaignMemberList();
    }
    public void renderFollowUpFalse() {
    	showtask = false;
    	OwnerTodo.clear();
    	renderCMresultsFalse();
    }
	//helper for CMresults Page Block
    public void renderCMresultsFalse(){
		SelectedCM.clear();
    	cMemberList.clear();
    	CMemberListNext.clear();
    }
	
	public Task getOwnerTodo() {
		OwnerTodo.OwnerId = CampaignOwner.get(SelectedCampaign);
		OwnerTodo.whatId = SelectedCampaign;
		OwnerTodo.priority = 'Normal';
		OwnerTodo.Status = 'Not Started';
		return OwnerTodo;
	}
	public void setOwnerTodo(Task OwnerTodo) {
		this.OwnerTodo = OwnerTodo;
	}
	
	public PageReference generateTodos(){
		copyList();
		PageReference apexRef = new PageReference('/701/o');
		if(CMemberList.size() >0){
		for(integer i=0;i<CMemberList.size();i++){
			if(SelectedCM.size() > 0){
				if(CMemberList.get(i).checkedMember == true && SelectedCM.get(CMemberList.get(i).Id) == true ){
					Task t = new task();
					if(CMOwner == true){
						if(CMemberList.get(i).OwnerId.startswith(UserKeyPrefix) && CMemberList.get(i).OwnerIsActive){
							t.OwnerId = CMemberList.get(i).OwnerId;
							if(CMemberList.get(i).CMType == 'Contact'){
								t.whatId = OwnerTodo.whatId;
							}
							t.priority = OwnerTodo.priority;
							t.Status = OwnerTodo.Status;
							t.ActivityDate = ownertodo.activitydate;
							t.subject = ownertodo.subject;
							t.description = ownertodo.description;
							t.WhoId = CMemberList.get(i).WhoId;
							t.isReminderSet = OwnerTodo.isReminderSet;
							t.ReminderDateTime = OwnerTodo.ReminderDateTime;
							OwnerTodoList.add(t);
						}else{
							BadCMemberList.add(CMemberList.get(i));
							apexRef = null;
						}
					}else{
						t.OwnerId = OwnerTodo.OwnerId;
						if(CMemberList.get(i).CMType == 'Contact'){
							t.whatId = OwnerTodo.whatId;
						}
						t.priority = OwnerTodo.priority;
						t.Status = OwnerTodo.Status;
						t.ActivityDate = ownertodo.activitydate;
						t.subject = ownertodo.subject;
						t.description = ownertodo.description;
						t.WhoId = CMemberList.get(i).WhoId;
						t.isReminderSet = OwnerTodo.isReminderSet;
						t.ReminderDateTime = OwnerTodo.ReminderDateTime;
						OwnerTodoList.add(t);	
					}
				}else{
					if(CMemberList.get(i).checkedMember == true && 	SelectedCM.get(CMemberList.get(i).Id) != true){
						System.debug(logginglevel.WARN, 'Warning: Integraty Problem between CMemberList State and SelectedCM State!');
					}
					if(CMemberList.get(i).checkedMember != true && SelectedCM.get(CMemberList.get(i).Id) == true){
						System.debug(logginglevel.WARN, 'Warning: Integraty Problem between CMemberList State and SelectedCM State!');
					}
				}
				
			}else {
				ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'No Campaign Member selected!');
				apexRef = null;
				showFollowUpButtonMessage = true;	
			}
		}

		insert OwnerTodoList;
		if(BadCMemberList.size() > 0){
			//call bad CM box
			apexRef = new PageReference('/apex/CampaignMemberTaskCreation');
			pageMessageTitle ='Task creation procceeded with errors';
    		pageMessageDetail ='For '+BadCMemberList.size()+' campaign members there could not been created a task. The reason might be that the owner is inactive or a queue. For the whole list ...';
    		pageMessageSeverity ='error';
    		pageMessageStrength = 2;
    		showPageMessage = true;
		}	
		}else{
			apexRef = null;
			showFollowUpButtonMessage = true;
		}
		return apexRef;
	}
            
    //get List of Campaign Status for selection
    public List<SelectOption> getItemsCampaignStatus() {

		List<SelectOption> options = new List<SelectOption>();
		for(Integer i = 0;i < P.size();i++ ){
			options.add(new SelectOption(P[i].getValue(),P[i].getLabel()));
		}
        return options;
    }
    public void setSelectCampaignStatus(String SelectedStatus) {
        this.SelectedStatus = SelectedStatus;  
    }
    public String getSelectCampaignStatus() {
        return SelectedStatus;
    }
	
	//get List MyCampaignMembers
	public void loadCampaignMemberList() {
    	showFollowUpButtonMessage = false;
    	allCheckboxes = false;
    	SelectedCM.clear();
    	cMemberList.clear();
    	CMemberListNext.clear();

		//set querycase!!! -> method -> TBD
		//SK: Über den String myquery sollte Count und Query gesteuert werden!
		//eine Methode  hinter dem "Go" Botton kann myquery setzen,
		//d.h. myquery muss dann global sein.
		//alle counts dann in countCMresults,
		//alle queries in queryCM
		
		if(countCMresults(myquery)<=1000){
			for (CampaignMember CM: queryCM(myquery)) {
	        	MyCampaignMember MyCM = new MyCampaignMember();
	        	if (CM != null) {
	        		try {
		        		if(CM.ContactId == null){
		        			MyCM.WhoId = CM.LeadId;
		        			MyCM.FirstName = CM.Lead.FirstName;
		        			MyCM.LastName = CM.Lead.LastName;
		        			MyCM.Email = CM.Lead.Email;
		        			MyCM.Employer = CM.Lead.Company;
		        			MyCM.City = CM.Lead.City;
		        			MyCM.Status = CM.Status;
		        			MyCM.CMType = 'Lead';
		        			MyCM.OwnerId =CM.Lead.OwnerId;	
		        			MyCM.ZipCode = CM.Lead.PostalCode;
		        			MyCM.NumberOfEmployees = CM.Lead.NumberOfEmployees;
		        			MyCM.Title = CM.Lead.Title;
		        			MyCM.OwnerIsActive = CM.Lead.Owner.IsActive;
		        		} else {
		        			MyCM.WhoId = CM.ContactId;
		        			MyCM.FirstName = CM.Contact.FirstName;
		        			MyCM.LastName = CM.Contact.LastName;
		        			MyCM.Email = CM.Contact.Email;
		        			MyCM.Employer = CM.Contact.Account.Name;
		        			MyCM.City = CM.Contact.MailingCity;
		        			MyCM.Status = CM.Status;
		        			MyCM.CMType = 'Contact';
		        			MyCM.OwnerId = CM.Contact.OwnerId;
		        			MyCM.ZipCode = CM.Contact.MailingPostalCode;
		        			MyCM.NumberOfEmployees = CM.Contact.Account.NumberOfEmployees;
		        			MyCM.Title = CM.Contact.Title;
		        			MyCM.OwnerIsActive = CM.Contact.Owner.IsActive;
		        		}
		        		MyCM.Id = CM.Id;
		        		CMemberList.add(MyCM);
	        		} catch (exception e) {
	        			System.debug('CML Error Message: '+ e);
	        			}
	        	}
	    	}
		
		if(CMemberList != null && CMemberList.size()>count){
        	for(Integer i=0; i<count; i++) {
                CMemberListNext.add(CMemberList.get(i));
            }
            shownext = true;
    	 	PageUntil = count;
        }else{
        	for(integer i=0;i<CMemberList.size();i++)
        	CMemberListNext.add(CMemberList.get(i));
        	shownext = false;
        	showprev = false;
    	 	PageUntil = CMemberList.size();
        	}
        	if(CMemberList.size() >0){
        		PageNext = 1;
        		showPageMessage = false;
        	}else{
        		PageNext = 0;
        		pageMessageTitle ='No Campaign Members found.';
    			pageMessageDetail ='This campaign has no campaign members or the query result of your filter selection is empty. Please change your selection, select another campaign or make sure you have<a href="../701/o">added Campaign Members before</a>.';
    			pageMessageSeverity ='info';
    			pageMessageStrength = 2;
    			showPageMessage = true;
        		}
        	copydownlimit = 0;
        }else{
			pageMessageTitle ='Too many campaign members';
    		pageMessageDetail ='There are more than 1000 campaign members!'+
    							' Please use the filter panel to reduce the results for the table below!';
    		pageMessageSeverity ='info';
    		pageMessageStrength = 2;
    		showPageMessage = true;
		}
	}
	
	// get PickList Values for Select Campaign Picklist
    public List<SelectOption> getCampaigns() {
    	List<SelectOption> options = null;
    	options = new List<SelectOption>();
    	CampaignOwner.clear();
    	List<Campaign> lc = null;
        lc = [SELECT Id, Name, ownerId FROM Campaign WHERE Status = :SelectedStatus order by Name];
        if(lc.size() > 0){
        	for(Campaign c: lc) {
        		CampaignOwner.put(c.Id,c.ownerId);
            	options.add(new SelectOption(c.Id, c.Name));
        	}
        	showSelectButton = true;
        } else{
        	options.add(new SelectOption('', 'NONE'));
        	showSelectButton = false;
        }
        return options;
    }
    public String getCampaign() {
        return SelectedCampaign;
    }
    public void setCampaign(String SelectedCampaign) {
        this.SelectedCampaign = SelectedCampaign;  
    }
     
     //Paging methods Next() and Prev() 
     public void Next(){
        try{
        	copydownlimit += count;
            showprev = true;
            CMemberListNext.clear();
            Integer limit1 = 0;
    
            if(next+count < CMemberList.size())
                limit1 = next+count;
            else
            {
                limit1 = CMemberList.size();
                shownext = false;
            }
            PageNext = next;
            PageUntil = limit1;
            for(Integer i=next; i<limit1; i++)
            CMemberListNext.add(CMemberList[i]);
    
            Next+=count;
            allCheckboxes = false;
        }catch(Exception e){system.debug('Exception :'+e);}
        showFollowUpButtonMessage = false;
    }
    
    public void Prev(){
        try{
            shownext = true;
            copydownlimit -=count;
            CMemberListNext.clear();
            Integer limit1 = 0;        
            if(next-(count+count) > 0)
                limit1 = next-count;
            else{
                limit1 = next-count; 
                showprev = false;
            }
            PageNext = next-(count+count);
            if (PageNext == 0){PageNext = 1;}
            PageUntil = limit1;
            for(Integer i=next-(count+count); i<limit1; i++)    
            	CMemberListNext.add(CMemberList.get(i));
            	Next-=count; 
            	allCheckboxes = false;
        }catch(Exception e){system.debug('Exception :'+e);}
        showFollowUpButtonMessage = false;            
    }
    
    private void copyList(){
 		for(Integer i=0;i<CMemberListNext.size();i++){
    		CMemberList.set(copydownlimit+i, CMemberListNext.get(i));
     		if(CMemberListNext.get(i).checkedMember == true){
        		SelectedCM.put(CMemberListNext.get(i).Id,CMemberListNext.get(i).checkedMember);
    		}
    		if(CMemberListNext.get(i).checkedMember == false){
        		SelectedCM.remove(CMemberListNext.get(i).Id);
    		}
		}   	
    }
    
    public Integer getCMemberList_size(){
    	return 	CMemberList.size();
    }
    public Integer PageNext {get; set;}
    public Integer PageUntil {get; set;}  



// update V1.1: filter criteria in order to support more than 1000 CMs
    //methods for Filter Status Field
    static Schema.DescribeFieldResult FS = CampaignMember.Status.getDescribe();
	static List<Schema.PicklistEntry> FSP = FS.getPicklistValues();  
    private String startFilterStatus = FSP[0].getValue();

    public List<SelectOption> getFilterStatusItems() {

		List<SelectOption> options = new List<SelectOption>();
		for(Integer i = 0;i < FSP.size();i++ ){
			options.add(new SelectOption(FSP[i].getValue(),FSP[i].getLabel()));
		}
        return options;
    }
    public String selectedFilterStatus {get; set;}
    
    //methods for Filter Type Field
    public List<SelectOption> getFilterTypeItems() {

		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('Both','Both'));
		options.add(new SelectOption('Lead','Lead'));
		options.add(new SelectOption('Contact','Contact'));
        return options;
    }
    public String selectedFilterType{get; set;}
    
    // Filter Title, No.Employees and zip code fields
     public String Title {get; set;}
     public Integer EmployeesFrom {get; set;}
     public Integer EmployeesTo {get; set;}
     public String Zip {get; set;}   
     //part strings for query
	private String filterTitle;
	private String filterEmployees;
	private String filterZip;
	
	public void gofilter(){
		//build Title filter string
		//if(Title.length()>0){
		if(Title != null){
			 if(selectedFilterType == 'both'){
				filterTitle =' AND (Contact.Title LIKE \''+Title+'%\' OR Lead.Title LIKE \''+Title+'%\')';
			}
			if(selectedFilterType =='Lead'){
				filterTitle =' AND Lead.Title LIKE \''+Title+'%\'';
			}
			if(selectedFilterType =='Contact'){
				filterTitle =' AND Contact.Title LIKE \''+Title+'%\'';
			}
		}else{
			filterTitle =' ';
		}
		//build Zip filter string
		//if(Zip.length()>0){
		if(Zip != null){
			 if(selectedFilterType =='Both'){
				filterZip =' AND (Lead.PostalCode LIKE \''+Zip+'%\' OR Contact.MailingPostalCode LIKE \''+Zip+'%\')';
			}
			if(selectedFilterType =='Lead'){
				filterZip =' AND Lead.PostalCode LIKE \''+Zip+'%\'';
			}
			if(selectedFilterType =='Contact'){
				filterZip =' AND Contact.MailingPostalCode LIKE \''+Zip+'%\'';
			}
		}else{
			filterZip =' ';
		}
		//build Employees# filer string
		if(EmployeesFrom != 0 && EmployeesFrom != null){
			if(EmployeesTo != 0 && EmployeesTo != null){
				if(selectedFilterType =='Both'){
					filterEmployees =' AND ((Contact.Account.NumberOfEmployees < '+EmployeesTo+'  AND  Contact.Account.NumberOfEmployees >'+EmployeesFrom+') OR (Lead.NumberOfEmployees < '+EmployeesTo+' AND Lead.NumberOfEmployees > '+EmployeesFrom+'))';
				}
				if(selectedFilterType =='Lead'){
					filterEmployees =' AND (Lead.NumberOfEmployees < '+EmployeesTo+' AND Lead.NumberOfEmployees > '+EmployeesFrom+')';
				}
				if(selectedFilterType =='Contact'){
					filterEmployees =' AND (Contact.Account.NumberOfEmployees < '+EmployeesTo+'  AND  Contact.Account.NumberOfEmployees >'+EmployeesFrom+')';
				}
			}else{
				if(selectedFilterType =='Both'){
					filterEmployees =' AND (Contact.Account.NumberOfEmployees >'+EmployeesFrom+' OR Lead.NumberOfEmployees > '+EmployeesFrom+')';
				}
				if(selectedFilterType =='Lead'){
					filterEmployees =' AND Lead.NumberOfEmployees > '+EmployeesFrom;
				}
				if(selectedFilterType =='Contact'){
					filterEmployees =' AND  Contact.Account.NumberOfEmployees >'+EmployeesFrom;
				}
			}
		}else{
			if(EmployeesTo != 0 && EmployeesTo != null){
				if(selectedFilterType =='Both'){
					filterEmployees =' AND (Contact.Account.NumberOfEmployees < '+EmployeesTo+' OR Lead.NumberOfEmployees < '+EmployeesTo+')';
				}
				if(selectedFilterType =='Lead'){
					filterEmployees =' AND Lead.NumberOfEmployees < '+EmployeesTo;
				}
				if(selectedFilterType =='Contact'){
					filterEmployees =' AND Contact.Account.NumberOfEmployees < '+EmployeesTo;
				}
			}else{
				filterEmployees =' ';
			}
		}
		myquery = selectedFilterType;
		loadCampaignMemberList();
	}


	// dynamic queries
	public List<CampaignMember> queryCM(String querycase){
		//default List
    	List<CampaignMember> CMList = new List<CampaignMember>();
    	String query;
    	if(querycase == 'default'){
	    	query = 'Select Id, LeadId, Lead.Company, Lead.Email, Lead.FirstName, Lead.LastName, Lead.OwnerId, Lead.Owner.IsActive, Lead.City, ContactId, Contact.Account.Name, Contact.Email, Contact.FirstName, Contact.LastName, Contact.OwnerId, Contact.Owner.IsActive, Contact.MailingCity, Contact.MailingPostalCode, Contact.Account.NumberOfEmployees, Contact.Title, Lead.PostalCode, Lead.NumberOfEmployees, Lead.Title, Status from CampaignMember WHERE CampaignId ='+'\''+SelectedCampaign+'\''+' ORDER BY Lead.LastName , Contact.LastName limit 1000';
    	}
    	if(querycase == 'both'){
	    	query = 'Select Id, LeadId, Lead.Company, Lead.Email, Lead.FirstName, Lead.LastName, Lead.OwnerId, Lead.Owner.IsActive, Lead.City, ContactId, Contact.Account.Name, Contact.Email, Contact.FirstName, Contact.LastName, Contact.OwnerId, Contact.Owner.IsActive, Contact.MailingCity, Contact.MailingPostalCode, Contact.Account.NumberOfEmployees, Contact.Title, Lead.PostalCode, Lead.NumberOfEmployees, Lead.Title, Status from CampaignMember WHERE CampaignId ='+'\''+SelectedCampaign+'\''+filterZip+filterTitle+filterEmployees+' AND Status='+'\''+selectedFilterStatus+'\''+' ORDER BY Lead.LastName , Contact.LastName limit 1000';
    	}
    	if(querycase == 'Lead'){
	    	query = 'Select Id, LeadId, ContactId, Lead.Company, Lead.Email, Lead.FirstName, Lead.LastName, Lead.OwnerId, Lead.Owner.IsActive, Lead.City,  Lead.PostalCode, Lead.NumberOfEmployees, Lead.Title, Status from CampaignMember WHERE CampaignId ='+'\''+SelectedCampaign+'\''+' AND ContactId=null'+filterZip+filterTitle+filterEmployees+' AND Status='+'\''+selectedFilterStatus+'\''+' ORDER BY Lead.LastName limit 1000';
    	}
    	if(querycase == 'Contact'){
	    	query = 'Select Id, ContactId, LeadId, Contact.Account.Name, Contact.Email, Contact.FirstName, Contact.LastName, Contact.OwnerId, Contact.Owner.IsActive, Contact.MailingCity, Contact.MailingPostalCode, Contact.Account.NumberOfEmployees, Contact.Title, Status from CampaignMember WHERE CampaignId ='+'\''+SelectedCampaign+'\''+' AND LeadId=null'+filterZip+filterTitle+filterEmployees+' AND Status='+'\''+selectedFilterStatus+'\''+' ORDER BY Contact.LastName limit 1000';
    	}
    	CMList = Database.query(query);
    	return CMList;
	}
	public Integer countCMresults(String querycase){
		Integer queryCount = 0;
		String query;
		if(querycase =='default'){
			query = 'Select count() from CampaignMember WHERE CampaignId ='+'\''+SelectedCampaign+'\' limit 2000';
		}
		if(querycase =='both'){
			query = 'Select count() from CampaignMember WHERE CampaignId ='+'\''+SelectedCampaign+'\''+filterZip+filterTitle+filterEmployees+' AND Status='+'\''+selectedFilterStatus+'\' limit 2000';
		}
		if(querycase =='Lead'){
			query = 'Select count() from CampaignMember WHERE CampaignId ='+'\''+SelectedCampaign+'\''+' AND ContactId=null'+filterZip+filterTitle+filterEmployees+' AND Status='+'\''+selectedFilterStatus+'\' limit 2000';
		}
		if(querycase =='Contact'){
			query = 'Select count() from CampaignMember WHERE CampaignId ='+'\''+SelectedCampaign+'\''+' AND LeadId=null'+filterZip+filterTitle+filterEmployees+' AND Status='+'\''+selectedFilterStatus+'\''+' limit 2000';
		}
		queryCount = Database.countQuery(query);
		return queryCount;
	}
}