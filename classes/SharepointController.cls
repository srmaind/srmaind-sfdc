public with sharing class SharepointController 
{
    //--to stored json of selected files list
    public String listDocumentWrapperJsonStr { get; set; }
    
    String accessToken;
    
    SharepointAuthorization__c sharepointAuth;
    
    public List<FolderAndFilesFromSP> listFolderAndFilesFromSP{get;set;}
    
    //--selected files list
    public List<DocumentWrapper> listdocWrapper{get;set;}
    
    //--currently displayed list parent
    String parent;
    
    //--No. of displayed folders
    Integer currentFolderCount;
    
    //--No. of displayed folders and files
    public Integer displayedItemCount {get;set;}
    
    //--total folders + files in selected directory
    public Integer folderItemCount    {get;set;}
    
    //--maximum Items per page
    public Integer recordLimit        {get;set;}
    
    //--No. of displayed files
    Integer currentFileCount;
    
    //--Page numbers
    public Integer pageCount          {get;set;}
    
    //--Page no on which folders and files are mixed
    Integer folderFilePageNo;
    
    public SharepointController(){
        
        init();
        recordLimit        = 15;
        listdocWrapper = new List<DocumentWrapper>();
        listFolderAndFilesFromSP = new List<FolderAndFilesFromSP>();
        
        accessToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik1uQ19WWmNBVGZNNXBPWWlKSE1iYTlnb0VLWSJ9.eyJhdWQiOiIwMDAwMDAwMy0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDAvcHJheGFzLnNoYXJlcG9pbnQuY29tQDYyZWVmZmE5LTdiYTItNDc5MS05YzdlLWQ1NGQzNWY0MDQyMyIsImlzcyI6IjAwMDAwMDAxLTAwMDAtMDAwMC1jMDAwLTAwMDAwMDAwMDAwMEA2MmVlZmZhOS03YmEyLTQ3OTEtOWM3ZS1kNTRkMzVmNDA0MjMiLCJuYmYiOjE0NTQ5NTEyMzUsImV4cCI6MTQ1NDk5NDQzNSwibmFtZWlkIjoiMTAwMzdmZmU5NTAwNWZhMiIsImFjdG9yIjoiYTdjY2I1MWMtYjE3NS00ZTBmLTgwNjQtNzNmODA5M2RmYTMzQDYyZWVmZmE5LTdiYTItNDc5MS05YzdlLWQ1NGQzNWY0MDQyMyIsImlkZW50aXR5cHJvdmlkZXIiOiJ1cm46ZmVkZXJhdGlvbjptaWNyb3NvZnRvbmxpbmUifQ.lvKqAbDs1UBbq84ET5HsVmlZnUpNXJRf49J5OfmDL-gsSm65cLKQjQ6sR_XtUxqZ-PZSYNRvM2sD1Kk5vi5J58tmk7PgyQLLwfmM6tLrdB1AzJRNB1QX-wXEoYx3BAfjfZxl17GvFKf3JtAK7pqym9HRtL7scD6QkqiQWsiuNwx1W7z9Y_RMqTQrj6845GYrI5Gy4NWI8zGYgQAl5ywkbt9HlO3pnPB4Qq0mw0uFxzoaeT30XW1aeAvlWR6ypeCbk4SJMDI9fvTvC_kEodADJqKRXFjOVmV91EjD2dloEDqlN1XMl3lNc-2ymIzQOCi-rgJ1tTcYnsVODarJIApEGg';   
    }
    
    void init() {
        
        currentFolderCount = 0;
        displayedItemCount = 0;
        folderItemCount    = 0; 
        currentFileCount   = 0;
        pageCount          = 1;
        folderFilePageNo   = -1;
    }
    String getAccessToken(){
        try {
            
            SharepointAuthorization__c sharepointAuth = new SharepointAuthorization__c();
            
            //--autorization parameters to get access token
            sharepointAuth = [ SELECT Client_Id__c,
                                      Redirect_URI__c,
                                      audience_principal_ID__c, 
                                      Bearer_realm__c,
                                      Client_Secret__c,
                                      Refresh_Token__c,
                                      Site__c
                               FROM SharepointAuthorization__c LIMIT 1];
            
            //--Make http request to get access token from refresh token            
            HttpRequest req = new HttpRequest();
            
            req.setEndpoint('https://accounts.accesscontrol.windows.net/'+
                            sharepointAuth.Bearer_realm__c+
                            '/tokens/OAuth/2');
                            
            req.setMethod('POST');
            
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Accept','application/json;odata=verbose');
            
            String reqBody = 'grant_type=refresh_token' +
                             '&client_id='+sharepointAuth.Client_Id__c+
                             EncodingUtil.URLENCODE('@','UTF-8')+
                             +sharepointAuth.Bearer_realm__c+
                             '&client_secret='+ EncodingUtil.URLENCODE(sharepointAuth.Client_Secret__c,'UTF-8') +
                             '&refresh_token='+ sharepointAuth.Refresh_Token__c +
                             '&redirect_uri='+EncodingUtil.URLENCODE(sharepointAuth.Redirect_URI__c,'UTF-8')+
                             '&resource='+sharepointAuth.audience_principal_ID__c+EncodingUtil.URLENCODE('/','UTF-8')+
                             sharepointAuth.Site__c+EncodingUtil.URLENCODE('@','UTF-8')+
                             sharepointAuth.Bearer_realm__c;
                                             
            req.setBody(reqBody);
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            SharepointController.AccessDetails accessDetails = (SharepointController.AccessDetails)JSON.deserialize(res.getBody(), SharepointController.AccessDetails.class);
            System.debug('Access-token::'+accessDetails.access_token);
            
            return accessDetails.access_token;
        } catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Exception Occured while retrieving access token'+e.getMessage()));
            return '';   
        }
    
    }
    
    public void browseSharedDocuments(){
        try {
            
            sharepointAuth = [ SELECT Client_Id__c,
                                      Redirect_URI__c,
                                      audience_principal_ID__c, 
                                      Bearer_realm__c,
                                      Client_Secret__c,
                                      Refresh_Token__c,
                                      Site__c
                               FROM SharepointAuthorization__c LIMIT 1];
            
            currentFolderCount = 0;
            
            folderItemCount = getItemCountOfParentDirectory();
            
            //--getFoldersAndFiles from parent directory
            getFoldersAndFiles('https://'+sharepointAuth.Site__c+                   '/_api/Web/GetFolderByServerRelativeUrl(\'/Gedeelde%20%20documenten\')');
            
            //--Remove parent tracer element bcoz no need in root directory
            listFolderAndFilesFromSP.remove(0);
            
            displayedItemCount = listFolderAndFilesFromSP.size();
            
        } catch(Exception e) {
            System.debug('Exception occured while retrieving authorization parameters!!'+e.getMessage());
        }
        
    }
    
    Integer getItemCountOfParentDirectory(){
        try
        {
            //--Request to get item count of root directory
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://'+sharepointAuth.Site__c + 
                            '/_api/Web/GetFolderByServerRelativeUrl(\'/Gedeelde%20%20documenten\')/ItemCount');
                            
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer '+accessToken);
            req.setHeader('Accept','application/json;odata=verbose');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            map<String, Map<String, String>> mapFolderToItemCount =  (map<String, Map<String, String>>)JSON.deserialize(res.getBody(), map<String, Map<String, String>>.class);
            return Integer.valueof(mapFolderToItemCount.get('d').get('ItemCount'));
        }
        catch(Exception e){
            System.debug('Error occured while retrieving item Count Of Parent Directory');
            return 0;
        }
    }
    
    public void  getFoldersAndFiles() {
        
        init();
        
        //--Get selected item index from page
        Integer index = Integer.valueOf(Apexpages.currentPage().getParameters().get('listIndex'));
        
        //--Check if it is parent folder
        if(listFolderAndFilesFromSP[index].Name.equals('...')) {
            
            //--get immidiate parent of currently displayed directory
            String parentURL = getParentOfCurrentDirectory(listFolderAndFilesFromSP[index].endpoint+'/parentfolder?$select=__metadata');
            parent = parentURL;
            getFoldersAndFiles('https://'+sharepointAuth.Site__c +
                               '/_api/Web/GetFolderByServerRelativeUrl('+
                               parentURL+
                               ')');
                               
           System.debug('parentURL::'+parentURL);
           
           //--If it is root directory then remove parent tracer element from list         
           if(parentURL.equals('\'/Gedeelde%20%20documenten\'') == true) {
               
               System.debug('parentURLL::'+parentURL);
               listFolderAndFilesFromSP.remove(0);    
           }
        }
        
        //--Check if it is folder
        else if(! listFolderAndFilesFromSP[index].type.equals('SP.File')){
            
            //--Maintain immidiate parent
            parent = listFolderAndFilesFromSP[index].endpoint;
            
            //--Totals items in selected directory
            folderItemCount = listFolderAndFilesFromSP[index].totalItems;
            
            //--Get folders and files in selected Directory
            getFoldersAndFiles('https://'+sharepointAuth.Site__c +
                               '/_api/Web/GetFolderByServerRelativeUrl('+
                               listFolderAndFilesFromSP[index].endpoint+
                               ')');
        }
        else {
            //--If file sis selected then insert document by retrieving content
            createDocumentFromSPFile('https://'+sharepointAuth.Site__c +
                                     '/_api/Web/GetFileByServerRelativeUrl('+
                                     listFolderAndFilesFromSP[index].endpoint+
                                     ')/$value');
        }
        
        System.debug('parent::'+parent);
    }
    
    String getParentOfCurrentDirectory(String endPoint) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer '+accessToken);
            req.setHeader('Accept','application/json;odata=verbose');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug('Response::'+res.getBody());
            Map<string, map<String, Map<String, String>>> mapParentFolderResponse = (Map<string, map<String, Map<String, String>>>)JSON.deserialize(res.getBody(), Map<string, map<String, Map<String, String>>>.class);
          
            String parentURI = mapParentFolderResponse.get('d').get('__metadata').get('uri');
            
            return parentURI.substringBetween('(', ')');
        } catch(Exception e) {
            System.debug('Exception occured while retrieving parent::'+e.getMessage());
            return null;
        }
                    
    }
    
    void getFoldersAndFiles(String endPoint) {
        listFolderAndFilesFromSP = new List<FolderAndFilesFromSP>();
        
        //--Create instance to trace immidiate parent
        FolderAndFilesFromSP fileFromSP = new FolderAndFilesFromSP();
        fileFromSP.type             = 'SP.Folder';
        fileFromSP.Name             = '...';
        fileFromSP.endpoint         = endPoint;
        
        listFolderAndFilesFromSP.add(fileFromSP);
        
        SharepointDTO spDTO = callSharepointService(endPoint+'/folders?$select=Name,TimeLastModified,itemcount'+
                                                    '&$skip='+currentFolderCount+
                                                    '&$top='+recordLimit + 
                                                    '&$orderby=TimeLastModified%20desc');
        
        if(spDTO.d != null)
        { 
            if(spDTO.d.results.size() > 0)
            {
                //--Make list from response
                buildSPDTO(spDTO);
                //--increment displayedItemCount
                displayedItemCount += listFolderAndFilesFromSP.size()-1;
                currentFolderCount += listFolderAndFilesFromSP.size()-1;
            } 
        }
        
        //--If folders are lesser than items per page, fetch files
        if(listFolderAndFilesFromSP.size() - 1 < recordLimit)
        {
            
             
            Integer listFolderSize = (listFolderAndFilesFromSP.size() == 0) ? 0:listFolderAndFilesFromSP.size()-1;
            
            spDTO = callSharepointService(endPoint + '/files?$select=Name,TimeLastModified,ContentType'+
                                          '&$skip='+currentFileCount + 
                                          '&$top=' + Math.abs(recordLimit - listFolderSize)+
                                          '&$orderby=TimeLastModified%20desc');
            //--add files to list from response
            if(spDTO.d != null && spDTO.d.results.size() > 0)
            {
                //maintain page that contain folders and files
                if(currentFileCount == 0 && folderFilePageNo == -1)
                {
                    folderFilePageNo = pageCount + 1;
                }
                buildSPDTO(spDTO);
            
                //--increment filecount and displayedcount
                if(spDTO.d.results.size() > 0)
                {
                    currentFileCount   +=  spDTO.d.results.size();
                    displayedItemCount +=  spDTO.d.results.size();
                }
            }    
        }
    }
    
    void getPrevFoldersAndFiles(String endPoint) {
        //--Decrement displayedItemCount
        displayedItemCount = Math.abs(displayedItemCount - (listFolderAndFilesFromSP.size() - 1));
        
        System.debug('currentFolderCount::'+currentFolderCount);
        System.debug('listFolderAndFilesFromSP::'+listFolderAndFilesFromSP.size());
        System.debug('recordLimit::'+recordLimit);
        System.debug('currentFileCount::'+currentFileCount);
        System.debug('pageCount::'+pageCount);
        System.debug('folderFilePageNo::'+folderFilePageNo);
        
        //--If mix folder file page is demanded return result accordingly
        if(pageCount - 1 == folderFilePageNo) {
            System.debug('No. of file count::'+listFolderAndFilesFromSP.size());
            
            SharepointDTO spDTO = callSharepointService(endPoint+ 
                                                        '/folders?$select=Name,TimeLastModified,itemcount' +
                                                        '&$skip='+Math.abs(currentFolderCount - (recordLimit-(currentFileCount - (listFolderAndFilesFromSP.size()- 1)))) +
                                                        '&$top='+Math.abs(recordLimit-(currentFileCount - (listFolderAndFilesFromSP.size()- 1))) +
                                                        '&$orderby=TimeLastModified%20desc');
            
            //--update current file count
            currentFileCount = currentFileCount - (listFolderAndFilesFromSP.size()- 1);
            
            addParentTrackerElementToList(endPoint);
            
            if(spDTO.d != null)
            {
                buildSPDTO(spDTO);
            }
            
            System.debug('No. of folders::'+listFolderAndFilesFromSP.size());
            
            spDTO = callSharepointService(endPoint + '/files?$select=Name,TimeLastModified,ContentType' +
                                          '&$skip=0' +
                                          '&$top=' + Math.abs(recordLimit - (listFolderAndFilesFromSP.size() - 1)) +
                                          '&$orderby=TimeLastModified%20desc');
            if(spDTO.d != null)
            {
                buildSPDTO(spDTO);
            }
            
        }
        //--only files or folders are present
        else if(pageCount > folderFilePageNo) {
            if(folderFilePageNo != -1) {
                
                System.debug('pageCount > folderFilePageNo='+pageCount +' > '+ folderFilePageNo);
                
                SharepointDTO spDTO = callSharepointService(endPoint + 
                                                            '/files?$select=Name,TimeLastModified,ContentType' +
                                                            '&$skip=' + Math.abs((currentFileCount - ((listFolderAndFilesFromSP.size() - 1) -  recordLimit))) +
                                                            '&$top=' + recordLimit + 
                                                            '&$orderby=TimeLastModified%20desc');
                
                currentFileCount = Math.abs(currentFileCount - (listFolderAndFilesFromSP.size() - 1));
               
                addParentTrackerElementToList(endPoint);
                
                if(spDTO.d != null)
                {
                    buildSPDTO(spDTO) ;
                }
            }
            else {
                SharepointDTO spDTO = callSharepointService(endPoint + 
                                                            '/folders?$select=Name,TimeLastModified,itemcount' +
                                                            '&$skip=' + Math.abs(currentFolderCount - (listFolderAndFilesFromSP.size() - 1) - recordLimit) +
                                                            '&$top=' + recordLimit +
                                                            '&$orderby=TimeLastModified%20desc');
                                      
                currentFolderCount = Math.abs(currentFolderCount - (listFolderAndFilesFromSP.size() - 1));
               
                addParentTrackerElementToList(endPoint);
                if(spDTO.d != null) {
                    buildSPDTO(spDTO);
                }        
            }
        }
        //--only folders on previous page
        else if(pageCount <= folderFilePageNo) {
            
            System.debug('pageCount <= folderFilePageNo='+pageCount + ' <= '+ folderFilePageNo);
            Integer currentlyDisplayedFolderCount = 0;
            
            for(Integer i =1; i < listFolderAndFilesFromSP.size(); i++)
            {
                if(listFolderAndFilesFromSP[i].type.equals('SP.Folder'))
                {
                    currentlyDisplayedFolderCount++;
                }
            }
            SharepointDTO spDTO = callSharepointService(endPoint + 
                                                        '/folders?$select=Name,TimeLastModified,itemcount' +
                                                        '&$skip='+Math.abs(currentFolderCount - currentlyDisplayedFolderCount - recordLimit) +
                                                        '&$top='+recordLimit +
                                                        '&$orderby=TimeLastModified%20desc');
            
            currentFolderCount = Math.abs(currentFolderCount - currentlyDisplayedFolderCount);
            addParentTrackerElementToList(endPoint);
            if(spDTO.d != null){
                buildSPDTO(spDTO);
            }
            
            if(pageCount == folderFilePageNo) {
                currentFileCount = Math.abs(currentFileCount - (recordLimit - currentlyDisplayedFolderCount));   
            }   
        }   
    }
    
    void addParentTrackerElementToList(String endPoint) {
        
        listFolderAndFilesFromSP = new List<FolderAndFilesFromSP>();
        
        FolderAndFilesFromSP fileFromSP = new FolderAndFilesFromSP();
        fileFromSP.type             = 'SP.Folder';
        fileFromSP.Name             = '...';
        fileFromSP.endpoint         = endPoint;
        listFolderAndFilesFromSP.add(fileFromSP);
    }
    
    void buildSPDTO(SharepointDTO spDTO) {
        
        for(SharepointDTO.ResponseFromSP folder : spDTO.d.results)
        {
            FolderAndFilesFromSP fileFromSP = new FolderAndFilesFromSP();
            fileFromSP.type             = folder.metadata.type;
            fileFromSP.Name             = folder.Name;
            fileFromSP.endpoint         = folder.metadata.uri.substringBetween('(', ')');
            fileFromSP.lastModifiedDate = folder.TimeLastModified.format('dd/MM/yyyy');
            fileFromSP.totalItems       = folder.itemCount;
            //Date.valueOf(folder.TimeLastModified);
            
            listFolderAndFilesFromSP.add(fileFromSP);
        }      
    }
    
    SharepointDTO callSharepointService(String endPoint) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer '+accessToken);
            req.setHeader('Accept','application/json;odata=verbose');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug('Response::'+res.getBody());
            String resonseBody = res.getBody().replaceAll('__deferred', 'deferred');
            resonseBody = resonseBody.replaceAll('__metadata', 'metadata');
            System.debug('response body::'+resonseBody);
            SharepointDTO spDTO = (SharepointDTO)JSON.deserialize(resonseBody, SharepointDTO.class);
           
            return spDTO;
        } catch(Exception e){
            System.debug('Exception occured while retrieving folders or files from Sharepoint::'+e.getMessage());
            return null;
        }
    }
    
    void createDocumentFromSPFile(String endpoint) {
        try {
            Integer index = Integer.valueOf(Apexpages.currentPage().getParameters().get('listIndex'));
            Folder folder = [ SELECT Id FROM Folder WHERE Name = :'CustomEmailTempAttachment'];  
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer '+accessToken);
            req.setHeader('binaryStringResponseBody','true');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            Document document = new Document();
            document.Name = listFolderAndFilesFromSP[index].name;
            document.body = res.getBodyAsBlob();
            document.folderId = folder.id;
            
            insert document;
            //--Pass selcted file details on parent page
            if(document.id != null) {
                
                DocumentWrapper docWrapper = new DocumentWrapper();
                docWrapper.id = document.id;
                docWrapper.name = document.name;
                docWrapper.size = document.BodyLength;
                docWrapper.type = 'Document';
                listdocWrapper.add(docWrapper);
                listDocumentWrapperJsonStr = json.serialize(listdocWrapper);
                System.debug('listDocumentWrapperJsonStr::'+listDocumentWrapperJsonStr);
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Info,'Attachment created successfully...'));
            }
            else {
                
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error while creating attachment...Please try again or contact your administrator'));    
            }
        } catch(Exception e) {
            System.debug('Exception occured while inserting document::'+e.getMessage());
        }
    }
    
    public PageReference getNextFoldersAndFiles() 
    { 
        if(displayedItemCount < folderItemCount)
        {
         
            System.debug('url form:::'+'https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       parent+
                       ')');
            getFoldersAndFiles('https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       parent+
                       ')');
            pageCount++;
        }
        
        return null;
    }
    
    public PageReference getPreviousFoldersAndFiles() 
    {
        //if(pageCount > (folderItemCount/recordLimit)) {
            System.debug('url form:::'+'https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       parent+
                       ')');
            getPrevFoldersAndFiles('https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       parent+
                       ')');
            pageCount--;
            
        //}
        return null;
    }
    
    public void  displayItems() {
        
        init();
        if(parent != null) {
            getFoldersAndFiles('https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       parent+
                       ')');
        }        
    }
    public class FolderAndFilesFromSP
    {
        public String Name{get;set;}
        public String lastModifiedDate{get;set;}
        String endpoint;
        String type;
        Integer totalItems;
    }
    
    public class DocumentWrapper
    {
        String id;
        public String Name{get;set;}
        Integer size;
        String type;
        
    }
    
    class AccessDetails
    {
        String access_token;
    }
}