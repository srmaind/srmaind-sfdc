/**
  * @Description : Controller class for Sharepoint VF page
  * @Created Date: 27 Jan 2016
 */
public with sharing class SharepointControllerClone 
{
    //--to stored json of selected files list
    public String listDocumentWrapperJsonStr { get; set; }
    
    String accessToken;
    
    SharepointAuthorization__c sharepointAuth;
    
    public List<FolderAndFilesFromSP> listFolderAndFilesFromSP {get;set;}
    
    //--selected files list
    public List<DocumentWrapper> listdocWrapper {get;set;}
    
    //--currently displayed list parent
    String parent;
    
    //--No. of displayed folders
    Integer currentFolderCount;
    
    //--No. of displayed folders and files
    public Integer displayedItemCount {get;set;}
    
    //--total folders + files in selected directory
    public Integer folderItemCount    {get;set;}
    
    //--maximum Items per page
    public Integer recordLimit {get;set;}
    
    //--No. of displayed files
    Integer currentFileCount;
    
    //--Page numbers
    public Integer pageCount {get;set;}
    
    //--Page no on which folders and files are mixed
    Integer folderFilePageNo;
    
    //--Search functionality pagination
    public Boolean hasNext      { get; set; }
    public Boolean hasPrevious  { get; set; }
    public Integer totalPages   { get; set; }
    public String searchText    { get; set; }
    
    //--Constructor
    public SharepointControllerClone(){
        
        initProcess();
        recordLimit        = 15;
        folderItemCount    = 0; 
        folderItemCount = 0;
        currentFileCount = 0;
        listdocWrapper = new List<DocumentWrapper>();
        listFolderAndFilesFromSP = new List<FolderAndFilesFromSP>();
        
        accessToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik1uQ19WWmNBVGZNNXBPWWlKSE1iYTlnb0VLWSJ9.eyJhdWQiOiIwMDAwMDAwMy0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDAvcHJheGFzLnNoYXJlcG9pbnQuY29tQDYyZWVmZmE5LTdiYTItNDc5MS05YzdlLWQ1NGQzNWY0MDQyMyIsImlzcyI6IjAwMDAwMDAxLTAwMDAtMDAwMC1jMDAwLTAwMDAwMDAwMDAwMEA2MmVlZmZhOS03YmEyLTQ3OTEtOWM3ZS1kNTRkMzVmNDA0MjMiLCJuYmYiOjE0NTYwNjc0MzIsImV4cCI6MTQ1NjExMDYzMiwibmFtZWlkIjoiMTAwMzdmZmU5NTAwNWZhMiIsImFjdG9yIjoiYTdjY2I1MWMtYjE3NS00ZTBmLTgwNjQtNzNmODA5M2RmYTMzQDYyZWVmZmE5LTdiYTItNDc5MS05YzdlLWQ1NGQzNWY0MDQyMyIsImlkZW50aXR5cHJvdmlkZXIiOiJ1cm46ZmVkZXJhdGlvbjptaWNyb3NvZnRvbmxpbmUifQ.JUEOOMrgLU1RP90dF7l3tRfNtw47nNXA-7Y33kMAA3lkyaKAV41s2To0TlKDlS2OtKPiNG1gJpeBBFGMxtAF2mUoxvUYl2FtMDjrTg5I8yosKQEWBdVeHc8eBe6zQdMlpjwaB-fzCR8zSmj08mR8ksAS0btJIzXx4aM7iSicA1yEkxcpOoepbvl37-2e6W5pzUr5HGKSy_h97-PXgdKsvy5PiaSycvl3gwTnU6wQ6tiUvzI1ptyzWenVbauGIXOyB5H9W8-B-Xoyx7HKitABFggCMudTg_cRBZZ3IK32tF8L-E2oGBiFFZsKc02kSToTQO-IndB7ITSULzpNf586WA';
        System.debug('access Token::'+accessToken);
        if(String.isNotEmpty(accessToken)) {
            
            browseSharedDocuments();
        }
    }
    
    /**
      * @purpose : initialize Class variables
     */
    void initProcess() {
        
        currentFolderCount = 0;
        displayedItemCount = 0;
        currentFileCount   = 0;
        pageCount          = 1;
        folderFilePageNo   = -1;
        searchText = '';
        totalPages = 0;
        hasPrevious = false;
        hasNext = false;
    }
    
    /**
      * @purpose : Make HTTP request to Sharepoint
      * @Return  : HTTPResponse From Sharepoint
     */
    HTTPResponse makeCalloutToSharepoint(String endPoint, String method) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);              
            req.setMethod(method);
            req.setHeader('Authorization', 'Bearer '+accessToken);
            req.setHeader('Accept','application/json;odata=verbose');
            Http http = new Http();
            HTTPResponse response = http.send(req);
            
            return response;
            
        } catch(Exception e) {
            HTTPResponse response = new HTTPResponse();
            System.debug('Exception occured while making callout!!' + e.getMessage());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error occured while traversing Documents...Please try again or contact your administrator'));
            return response;
        }
    }
    
    /**
      * @purpose : get Access Token from resfresh token which is stored in SharepointAuthorization__c
      * @Return  : String - Access Token
     */
    public String getAccessToken(){
        try {
            
            sharepointAuth = new SharepointAuthorization__c();
            
            //--autorization parameters to get access token
            sharepointAuth = [ SELECT Client_Id__c,
                                      Redirect_URI__c,
                                      audience_principal_ID__c, 
                                      Bearer_realm__c,
                                      Client_Secret__c,
                                      Refresh_Token__c,
                                      Site__c
                               FROM SharepointAuthorization__c LIMIT 1];
            
            if(  sharepointAuth != null                                    && 
                 String.isNotEmpty(sharepointAuth.Bearer_realm__c)         &&
                 String.isNotEmpty(sharepointAuth.Client_Id__c)            &&
                 String.isNotEmpty(sharepointAuth.Client_Secret__c)        &&
                 String.isNotEmpty(sharepointAuth.Refresh_Token__c)        &&
                 String.isNotEmpty(sharepointAuth.Redirect_URI__c)         &&
                 String.isNotEmpty(sharepointAuth.audience_principal_ID__c)&&
                 String.isNotEmpty(sharepointAuth.Site__c)
              ) {
                //--Make http request to get access token from refresh token            
                HttpRequest req = new HttpRequest();
                
                req.setEndpoint('https://accounts.accesscontrol.windows.net/'+
                                sharepointAuth.Bearer_realm__c+
                                '/tokens/OAuth/2');
                                
                req.setMethod('POST');
                
                req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
                req.setHeader('Accept','application/json;odata=verbose');
                
                String reqBody = 'grant_type=refresh_token' +
                                 '&client_id='+sharepointAuth.Client_Id__c +
                                 encodeString('@') +
                                 +sharepointAuth.Bearer_realm__c +
                                 '&client_secret=' + encodeString(sharepointAuth.Client_Secret__c) +
                                 '&refresh_token=' + sharepointAuth.Refresh_Token__c +
                                 '&redirect_uri='  + encodeString(sharepointAuth.Redirect_URI__c) +
                                 '&resource='      + sharepointAuth.audience_principal_ID__c + encodeString('/') +
                                 sharepointAuth.Site__c + encodeString('@') +
                                 sharepointAuth.Bearer_realm__c;
                                                 
                req.setBody(reqBody);
                
                Http http = new Http();
                HTTPResponse response = http.send(req);
                if(response.getStatusCode() == 200) {
                    SharepointControllerClone.AccessDetails accessDetails = (SharepointControllerClone.AccessDetails)JSON.deserialize(response.getBody(), SharepointControllerClone.AccessDetails.class);
                    return accessDetails.access_token;
                }
                else {
                     ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, response.getStatus() + ' Try Again or Contact your Administrator..'));
                     return '';     
                }
            }
            else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Exception Occured while retrieving access token'));
                
                return ''; 
            }
        } catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Exception Occured while retrieving access token'+e.getMessage()));
            return '';   
        }
    
    }
    
    
    /**
      * @purpose : encode string in UTF-8
      * @Return  : Encoded String
     */
    String encodeString(String inputToEncode)
    {
        String encodedString = '';
        try
        {
            encodedString = EncodingUtil.URLENCODE(inputToEncode,'UTF-8');
        } catch(Exception e)
        {
            System.debug('Error while encoding URL parameters'+e.getMessage());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error occured while encoding URL parameters...Please try again or contact your administrator'));
        }
        return encodedString;
    }
    
    /**
      * @purpose : browse Root directory
     */
    public void browseSharedDocuments(){
    
        /*sharepointAuth = [ SELECT Client_Id__c,
                                  Redirect_URI__c,
                                  audience_principal_ID__c, 
                                  Bearer_realm__c,
                                  Client_Secret__c,
                                  Refresh_Token__c,
                                  Site__c
                           FROM SharepointAuthorization__c LIMIT 1];*/
        System.debug('sharepointAuth::' + sharepointAuth);
        
        currentFolderCount = 0;
        
        folderItemCount = getItemCountOfParentDirectory();
        
        if(folderItemCount != 0) {   
            //--getFoldersAndFiles from parent directory
            getFoldersAndFiles('https://praxas.sharepoint.com/_api/Web/GetFolderByServerRelativeUrl(\'/Gedeelde%20%20documenten\')');
            
            //--Remove parent tracer element bcoz no need in root directory
            listFolderAndFilesFromSP.remove(0);
            
            displayedItemCount = listFolderAndFilesFromSP.size();
        }
    }
    
    /**
      * @purpose : get ItemCount Of Parent Folder(Shared Document)
      * @Return  : Item count in shared document
     */
    Integer getItemCountOfParentDirectory(){
        try
        {
            //--Request to get item count of root directory
            HTTPResponse response = makeCalloutToSharepoint('https://praxas.sharepoint.com/_api/Web/GetFolderByServerRelativeUrl(\'/Gedeelde' +
                                                            '%20%20' +
                                                            'documenten\')/ItemCount',
                                                            'GET');
            if(response.getStatusCode() == 200) {
            
                map<String, Map<String, String>> mapFolderToItemCount =  (map<String, Map<String, String>>)JSON.deserialize(response.getBody(), map<String, Map<String, String>>.class);
                
                if(mapFolderToItemCount != null) {
                    return Integer.valueof(mapFolderToItemCount.get('d').get('ItemCount'));
                }
                else {
                    return 0;
                }
            }
            else {
                 ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, response.getStatus() + ' Try Again or Contact your Administrator..'));
                 return 0;     
            } 
        }
        catch(Exception e){
            System.debug('Error occured while retrieving item Count Of Parent Directory');
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error occured while retrieving item Count Of Parent Directory...Please try again or contact your administrator'));
            return 0;
        }
    }
    
    /**
      * @purpose : get Folders and Files(invoke from Vf page onclick of any folder or file)
      * @Return  : Item count in shared document
     */
    public void  getFoldersAndFiles() {
        
        initProcess();
        
        //--Get selected item index from page
        String indexOfSelectedItem = Apexpages.currentPage().getParameters().get('listIndex');
        System.debug('indexOfSelectedItem::' + indexOfSelectedItem);
        System.debug('listFolderAndFilesFromSP::' + listFolderAndFilesFromSP);
        
        if( String.isNotEmpty(indexOfSelectedItem)  
           && !listFolderAndFilesFromSP.isEmpty()                       
           && String.isNotEmpty(listFolderAndFilesFromSP[Integer.valueOf(indexOfSelectedItem)].Name)   
           && String.isNotEmpty(listFolderAndFilesFromSP[Integer.valueOf(indexOfSelectedItem)].endpoint)) {
                
            Integer index = Integer.valueOf(indexOfSelectedItem);
            //--Check if it is parent folder
            if(listFolderAndFilesFromSP[index].Name.equals('...')) {
                
                //--get immidiate parent of currently displayed directory
                String parentURL = getParentOfCurrentDirectory(listFolderAndFilesFromSP[index].endpoint + 
                                                               '/parentfolder?$select=__metadata');
                if(String.isNotEmpty(parentURL)) {
                    
                    parent = parentURL;
                    getFoldersAndFiles('https://praxas.sharepoint.com/_api/Web/GetFolderByServerRelativeUrl(' +
                                        parentURL +
                                       ')');
                                       
                   //--If it is root directory then remove parent tracer element from list         
                   if(parentURL.equals('\'/Gedeelde%20%20documenten\'') == true) {
                       listFolderAndFilesFromSP.remove(0);    
                   }
                }
            }
            
            //--Check if it is folder
            else if(listFolderAndFilesFromSP != null 
                    && ! listFolderAndFilesFromSP[index].type.equals('SP.File') ){
                if(listFolderAndFilesFromSP[index].totalItems > 0) {
                //--Maintain immidiate parent
                    parent = listFolderAndFilesFromSP[index].endpoint;
                    
                    //--Totals items in selected directory
                    folderItemCount = listFolderAndFilesFromSP[index].totalItems;
                    folderItemCount = (folderItemCount == null) ? 0 : folderItemCount;
                    
                    //--Get folders and files in selected Directory
                    getFoldersAndFiles('https://praxas.sharepoint.com/_api/Web/GetFolderByServerRelativeUrl('+
                                       listFolderAndFilesFromSP[index].endpoint+
                                       ')');
                   System.debug('listFolderAndFilesFromSP::' + listFolderAndFilesFromSP );    
                }
                else {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Selected Folder is empty'));
                    return;
                }
            }
            
            //--Check if it is file
            else {
                //--If file is selected then insert document by retrieving content
                createDocumentFromSPFile('https://praxas.sharepoint.com/_api/Web/GetFileByServerRelativeUrl('+
                                         listFolderAndFilesFromSP[index].endpoint+
                                         ')/$value', Integer.valueOf(indexOfSelectedItem));
                
            }
            System.debug('parent::'+parent);
        }
        else {
            System.debug('Error occured while retrieving items from selected folder');
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Invalid endpoint or Name for selected folder...Please try again or contact your administrator'));
            return;
        }
    }
    
    /**
      * @purpose : get Parent Of Currently displayed Directory
      * @Return  : String - parent url of selected directory
     */
    String getParentOfCurrentDirectory(String endPoint) {
        try {
            HTTPResponse response = makeCalloutToSharepoint(endPoint,'GET');
            
            if(response.getStatusCode() == 200) {
                Map<string, map<String, Map<String, String>>> mapParentFolderResponse = (Map<string, map<String, Map<String, String>>>)JSON.deserialize(response.getBody(), Map<string, map<String, Map<String, String>>>.class);
                
                if(mapParentFolderResponse != null) {
                    String parentURI = mapParentFolderResponse.get('d').get('__metadata').get('uri');
                    return parentURI.substringBetween('(', ')');
                }
                else {
                    System.debug('Error occured while retrieving parent');
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error occured while retrieving parent...Please try again or contact your administrator'));
                    return '';
                }
            }
            else {
                 ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, response.getStatus() + 'Try Again or Contact your Administrator..'));
                 return '';     
            }
        } catch(Exception e) {
            System.debug('Exception occured while retrieving parent::'+e.getMessage());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error occured while retrieving parent...Please try again or contact your administrator'));
            return null;
        }
                    
    }
    
    /**
      * @purpose : get Folders And Files
     */
    void getFoldersAndFiles(String endPoint) {
        
        listFolderAndFilesFromSP = new List<FolderAndFilesFromSP>();
        
        //--Create instance to trace immidiate parent
        addParentTrackerElementToList(endPoint);
        
        //--Get folders in selected directory
        SharepointDTO spDTO = callSharepointService(endPoint + '/folders?$select=Name,TimeLastModified,itemcount'+
                                                    '&$filter=ListItemAllFields%20ne%20null' +
                                                    '&$skip=' + currentFolderCount +
                                                    '&$top=' + recordLimit + 
                                                    '&$orderby=TimeLastModified%20desc');
        
        if(spDTO.d != null && spDTO.d.results.size() > 0){
            //--Make list from response
            buildSPDTO(spDTO);
            //--increment displayedItemCount
            displayedItemCount += listFolderAndFilesFromSP.size() - 1;
            currentFolderCount += listFolderAndFilesFromSP.size() - 1;     
        }
        
        //--If folders are lesser than items per page, fetch files
        if(listFolderAndFilesFromSP.size() - 1 < recordLimit){ 
            Integer listFolderSize = (listFolderAndFilesFromSP.size() == 0) ? 0:listFolderAndFilesFromSP.size()-1;
            
            //--Get files from selected directory
            spDTO = callSharepointService(endPoint + '/files?$select=Name,TimeLastModified,ContentType'+
                                          '&$filter=ListItemAllFields%20ne%20null' +
                                          '&$skip='+currentFileCount + 
                                          '&$top=' + Math.abs(recordLimit - listFolderSize)+
                                          '&$orderby=TimeLastModified%20desc');
                                          
            //--add files to list from response
            if(spDTO.d != null && spDTO.d.results.size() > 0){
                //maintain page that contain folders and files
                if(currentFileCount == 0 && folderFilePageNo == -1) {
                    folderFilePageNo = pageCount;
                }
                buildSPDTO(spDTO);
                
                //--increment filecount and displayedcount
                if(spDTO.d.results.size() > 0){
                    currentFileCount   +=  spDTO.d.results.size();
                    displayedItemCount +=  spDTO.d.results.size();
                }
            }    
        }
    }
    
    /**
      * @purpose : get Folders And Files when click on previous button
     */
    void getPrevFoldersAndFiles(String endPoint) {
        //--Decrement displayedItemCount
        displayedItemCount = Math.abs(displayedItemCount - (listFolderAndFilesFromSP.size() - 1));
        
        //--If mix folder file page is demanded return result accordingly
        if(pageCount - 1 == folderFilePageNo) {
            
            SharepointDTO spDTO = callSharepointService(endPoint+ 
                                                        '/folders?$select=Name,TimeLastModified,itemcount' +
                                                        '&$filter=ListItemAllFields%20ne%20null' +
                                                        '&$skip='+Math.abs(currentFolderCount - (recordLimit-(currentFileCount - (listFolderAndFilesFromSP.size()- 1)))) +
                                                        '&$top='+Math.abs(recordLimit-(currentFileCount - (listFolderAndFilesFromSP.size()- 1))) +
                                                        '&$orderby=TimeLastModified%20desc');
            
            //--update current file count
            currentFileCount = currentFileCount - (listFolderAndFilesFromSP.size()- 1);
            
            addParentTrackerElementToList(endPoint);
            
            if(spDTO.d != null){
                buildSPDTO(spDTO);
            }
            
            spDTO = callSharepointService(endPoint + '/files?$select=Name,TimeLastModified,ContentType' +
                                          '&$filter=ListItemAllFields%20ne%20null' +
                                          '&$skip=0' +
                                          '&$top=' + Math.abs(recordLimit - (listFolderAndFilesFromSP.size() - 1)) +
                                          '&$orderby=TimeLastModified%20desc');
            if(spDTO.d != null) {
                buildSPDTO(spDTO);
            }  
        }
        //--only files or folders are present
        else if(pageCount > folderFilePageNo) {
            if(folderFilePageNo != -1) {
                SharepointDTO spDTO = callSharepointService(endPoint + 
                                                            '/files?$select=Name,TimeLastModified,ContentType' +
                                                            '&$filter=ListItemAllFields%20ne%20null' +
                                                            '&$skip=' + Math.abs((currentFileCount - (listFolderAndFilesFromSP.size() - 1)) -  recordLimit) +
                                                            '&$top=' + recordLimit + 
                                                            '&$orderby=TimeLastModified%20desc');
                
                currentFileCount = Math.abs(currentFileCount - (listFolderAndFilesFromSP.size() - 1));
                addParentTrackerElementToList(endPoint);
                if(spDTO.d != null) {
                    buildSPDTO(spDTO) ;
                }
            }
            else {
                SharepointDTO spDTO = callSharepointService(endPoint + 
                                                            '/folders?$select=Name,TimeLastModified,itemcount' +
                                                            '&$filter=ListItemAllFields%20ne%20null' +
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
            Integer currentlyDisplayedFolderCount = 0;
            for(Integer i =1; i < listFolderAndFilesFromSP.size(); i++) {
                if(listFolderAndFilesFromSP[i].type.equals('SP.Folder')) {
                    currentlyDisplayedFolderCount++;
                }
            }
            SharepointDTO spDTO = callSharepointService(endPoint + 
                                                        '/folders?$select=Name,TimeLastModified,itemcount' +
                                                        '&$filter=ListItemAllFields%20ne%20null' +
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
    
    /**
      * @purpose : add Parent Tracker Element To List
     */
    void addParentTrackerElementToList(String endPoint) {
        
        listFolderAndFilesFromSP = new List<FolderAndFilesFromSP>();
        
        FolderAndFilesFromSP fileFromSP = new FolderAndFilesFromSP();
        fileFromSP.type             = 'SP.Folder';
        fileFromSP.Name             = '...';
        fileFromSP.endpoint         = endPoint;
        listFolderAndFilesFromSP.add(fileFromSP);
    }
    
    /**
      * @purpose : Make list from HTTP response
     */
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
    
    /**
      * @purpose : call Sharepoint Service
      * @Return  : SharepointDTO class object
     */
    SharepointDTO callSharepointService(String endPoint) {
        HTTPResponse response = makeCalloutToSharepoint(endPoint, 'GET');
        if(response.getStatusCode() == 200) {
            if(String.isNotEmpty(response.getBody())) {
                String resonseBody = response.getBody().replaceAll('__deferred', 'deferred');
                resonseBody = resonseBody.replaceAll('__metadata', 'metadata');
                SharepointDTO spDTO = (SharepointDTO)JSON.deserialize(resonseBody, SharepointDTO.class);
                return spDTO;
            }
            else {
                SharepointDTO spDTO = new SharepointDTO();
                System.debug('Exception occured while making callout!!');
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error occured while traversing Documents...Please try again or contact your administrator'));
                return spDTO;
            }
        }
        else {
             ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, response.getStatus() + ' Try Again or Contact your Administrator..'));
             return null;     
        }
    }
    
    /**
      * @purpose : insert sharepoint file into document
     */
    void createDocumentFromSPFile(String endpoint, Integer selectedFileIndex) {
        HTTPResponse response;
        Folder folder;
        try {
            
            folder = [ SELECT Id FROM Folder WHERE Name = 'CustomEmailTempAttachment'];  
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer '+accessToken);
            req.setHeader('binaryStringResponseBody','true');
            Http http = new Http();
            response = http.send(req);
            
            if(response.getStatusCode() == 200) {
                Document document = new Document();
                document.Name = listFolderAndFilesFromSP[selectedFileIndex].name;
                document.body = response.getBodyAsBlob();
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
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Info,'Attachment created successfully...'));
                }
                else {
                    
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error while creating attachment...Please try again or contact your administrator'));    
                }
            } 
            else {
                 ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, response.getStatus() + ' Try Again or Contact your Administrator..'));
            }
        } catch(Exception e) {
            System.debug('Exception occured while inserting document::' + e.getMessage());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error while creating attachment...Please try again or contact your administrator')); 
        }
            
        
    }
    
    /**
      * @purpose : call Sharepoint Service
      * @Return  : SharepointDTO class object
     */
    public PageReference getNextFoldersAndFiles(){
        searchText = '';
        if(String.isNotEmpty(parent)) {
            if(displayedItemCount < folderItemCount)
            {
                pageCount++;
                System.debug('url form:::'+'https://praxas.sharepoint.com/_api/Web/GetFolderByServerRelativeUrl('+
                           parent+
                           ')');
                getFoldersAndFiles('https://praxas.sharepoint.com/_api/Web/GetFolderByServerRelativeUrl('+
                           parent+
                           ')');
                
            }
        }
        else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error occured while retrieving DownloadURL URL...Please try again or contact your administrator')); 
        }       
        return null;
    }
    
    /**
      * @purpose : Handel Prev link on page
      * @Return  : PageReference
     */
    public PageReference getPreviousFoldersAndFiles() { 
        pageCount--;
        searchText = '';
        if(pageCount > 1 && String.isNotEmpty(parent)) {
            
            getPrevFoldersAndFiles('https://praxas.sharepoint.com/_api/Web/GetFolderByServerRelativeUrl(' +
                       parent +
                       ')');
        }    
        return null;
    }
    
    /**
      * @purpose : Handel picklist value change on page
      * @Return  : PageReference
     */
    public void  displayItems() {
        
        initProcess();
        System.debug('recordLimit in displayItems::' + recordLimit);
        if(String.isNotEmpty(parent)) {
            getFoldersAndFiles('https://praxas.sharepoint.com/_api/Web/GetFolderByServerRelativeUrl('+
                       parent+
                       ')');
        }          
    }
    
    /**
      * @purpose : Handel del action on VF page
     */
    public void removeAttachment()
    {
        String selectedFileIndexToRemove = Apexpages.currentPage().getParameters().get('attachmentIndexVar');
        Integer index = Integer.valueOf(selectedFileIndexToRemove);
        System.debug('selectedFileIndexToRemove::' + selectedFileIndexToRemove);
        if(String.isNotEmpty(selectedFileIndexToRemove)){
            try {
                //listdocWrapper = new List<DocumentWrapper>();
                Document document = new Document(id = listdocWrapper[index].id); 
                delete document;
                System.debug('listdocWrapper before remove::' + listdocWrapper);
                System.debug('listdocWrapper size before remove::' + listdocWrapper.size());
                //List<DocumentWrapper> lstDocumentWrapper = new List<DocumentWrapper>();
                //System.debug('lstDocumentWrapper size before remove::' + lstDocumentWrapper.size());
                /*for (Integer i = 0; i < listdocWrapper.size(); i++) {
                    if (i != index) {
                        lstDocumentWrapper.add(listdocWrapper[i]);
                    }
                }*/
                //listdocWrapper = new List <DocumentWrapper>();
                listdocWrapper.remove(Integer.valueOf(selectedFileIndexToRemove));
                System.debug('listdocWrapper after remove::' + listdocWrapper);
                System.debug('listdocWrapper size after remove::' + listdocWrapper.size());
                if(! listdocWrapper.isEmpty()){
                    listDocumentWrapperJsonStr = json.serialize(listdocWrapper);
                }
                    
            } catch(Exception e) {
                System.debug('Exception occured while deleting document::'+e.getMessage());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Exception occured while removing Attachment...Please try again or contact your administrator'));
            }
       }
    }
    
    public void clearSearch() {
        initProcess();
        recordLimit        = 15;
        folderItemCount    = 0; 
        folderItemCount    = 0;
        currentFileCount   = 0;
        listFolderAndFilesFromSP = new List<FolderAndFilesFromSP>();
        if(String.isNotEmpty(accessToken)) {
            browseSharedDocuments();
        }    
    }
    /**
      * @purpose : init search functionality when user click on search button
     */
    public void initSearch() {
        listFolderAndFilesFromSP  = new List<FolderAndFilesFromSP>();
        //listdocWrapper = new List<DocumentWrapper>();
        totalPages = 0;
        hasPrevious = false;
        hasNext = false;
        recordLimit = 10;
        folderItemCount = 0;
        searchSharePointFiles();
    }
    
    /**
      * @purpose : get search result and initialize pagination parameters
     */
    void searchSharePointFiles() {
        if (String.isNotBlank(searchText)) {
            currentFileCount = 0;
            SharepointSearchResult searchResult = getSharePointFiles(currentFileCount);
            if (searchResult != null && searchResult.d != null) {
                folderItemCount = searchResult.d.query.PrimaryQueryResult.RelevantResults.TotalRows;
                totalPages = (Integer) Math.ceil(folderItemCount / recordLimit); 
                listFolderAndFilesFromSP = wrapResults(searchResult);
                pageCount = 1;
                hasPrevious = false;
                if (totalPages == 0 || pageCount == totalPages) {
                    hasNext = false;
                } else {
                    hasNext = true;
                }
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 
                                                            'An unexpected error has occurred'));
            }
        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'Please enter the text to search'));
        }
    }
    
    /**
      * @purpose : search SharePoint Files
     */
    public SharepointSearchResult getSharePointFiles(Integer startRow) {
        HTTPResponse response = makeCalloutToSharepoint('https://praxas.sharepoint.com/_api/search/query?'
                                              + 'querytext=\'' + encodeString(searchText)+
                                              + '\'&startrow=' + startrow
                                              + '&rowlimit=' + recordLimit
                                              + '&refinementfilters=\'IsDocument:true\''
                                              + '&selectproperties='
                                              + '\'LastModifiedTime,FileExtension,ServerRedirectedPreviewURL,Title,Path\'',
                                                'GET');
        
        SharepointSearchResult searchDetails;
        if(response.getStatusCode() == 200) {
            try {
                searchDetails = (SharepointSearchResult)JSON.deserialize(response.getBody(), SharepointSearchResult.class);
                System.debug('response of search result::' + searchDetails);
            } catch (System.JsonException jsonExcp) {
                System.debug('JSON Exception Occurred while deserializing result body : ' + jsonExcp);
            }
        }
        else {
             ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, response.getStatus() + 'Try Again or Contact your Administrator..'));     
        }
        return searchDetails;
    }
    
    /**
      * @purpose : make a list of files from search result
     */
    public List<FolderAndFilesFromSP> wrapResults(SharepointSearchResult searchResults) {
        listFolderAndFilesFromSP  = new List<FolderAndFilesFromSP>();

        try {
           
            for (SharepointSearchResult.Results_Y searchResult : 
                    searchResults.d.query.PrimaryQueryResult.RelevantResults.Table.Rows.results) {
                    
                FolderAndFilesFromSP resultWrapper = new FolderAndFilesFromSP();
                
                for (SharepointSearchResult.Results_Z property : searchResult.Cells.results) {
                    /*if (property.Key.equalsIgnoreCase('ServerRedirectedPreviewURL') && property.Value == null)
                    {
                        goto outer1;
                    }*/
                    if (property.Key.equalsIgnoreCase('Title')) {
                        resultWrapper.Name = property.Value;
                    }
                    if (property.Key.equalsIgnoreCase('Path')) {
                        System.debug('FilePath::' + property.Value);
                        if(String.isNotBlank(property.Value)) {
                            resultWrapper.endpoint = property.Value.substringAfter('https://praxas.sharepoint.com/');
                            resultWrapper.endpoint = '/' + resultWrapper.endpoint.replaceAll(' ','%20');
                        }
                    }
                    if (property.Key.equalsIgnoreCase('LastModifiedTime')) {
                        //String lastModifiedDate = Date.valueOf(property.Value);
                        System.debug('lastModifiedDate ::' + property.Value);
                        if(String.isNotEmpty(property.Value)) {
                            resultWrapper.lastModifiedDate = String.valueOf(Date.valueOf(property.Value));
                        }
                    }
                    if (property.Key.equalsIgnoreCase('FileExtension')) {
                        //String lastModifiedDate = Date.valueOf(property.Value);
                        System.debug('lastModifiedDate ::' + property.Value);
                        if(String.isNotEmpty(property.Value)) {
                            resultWrapper.type = property.Value;
                        }
                    }
                    
                    if (String.isNotBlank(resultWrapper.Name) && String.isNotBlank(resultWrapper.endpoint)) {
                        break;
                    }
                }
                listFolderAndFilesFromSP.add(resultWrapper);
                 //outer1;
            }
        } catch(System.Exception excp) {
            system.debug('Exception occurred while wrapping search results : ' + excp);
        }   
        return listFolderAndFilesFromSP;
    }
    
    /**
      * @purpose : handle next button on page[Search functionality]
     */
    public void next() {
        if (hasNext) {
            currentFileCount = currentFileCount + recordLimit;
            SharepointSearchResult searchResult = getSharePointFiles(currentFileCount);
            listFolderAndFilesFromSP = wrapResults(searchResult);
            pageCount++;
            hasPrevious = true;
            if (totalPages == 0 || pageCount == totalPages) {
                hasNext = false;
            } else {
                hasNext = true;
            }
        }
    }
    
    /**
      * @purpose : handle prev button on page[Search functionality]
     */
    public void previous() {
        if (hasPrevious) {
            currentFileCount = currentFileCount - recordLimit;
            SharepointSearchResult searchResult = getSharePointFiles(currentFileCount);
            listFolderAndFilesFromSP = wrapResults(searchResult);
            pageCount--;
            hasNext = true;
            if (totalPages == 0 || pageCount == 1) {
                hasPrevious = false;
            } else {
                hasPrevious = true;
            }
        }
    }
    
    /**
      * @purpose : navigate to specific page[Search functionality]
     */
    public void gotoPageNumber() {
        currentFileCount = (pageCount - 1)  * recordLimit;
        SharepointSearchResult searchResult = getSharePointFiles(currentFileCount);
        listFolderAndFilesFromSP = wrapResults(searchResult);
        if (totalPages == 0 || pageCount == 1) {
            hasPrevious = false;
        } else {
            hasPrevious = true;
        }
        if (totalPages == 0 || pageCount == totalPages) {
            hasNext = false;
        } else {
            hasNext = true;
        }
    }
    
    /**
      * @purpose : insert selected file as Document
     */
    public void insertSPFile(){
        String indexOfSelectedItem = Apexpages.currentPage().getParameters().get('fileIndex');
        System.debug('indexOfSelectedItem ::'+indexOfSelectedItem );
        if(String.isNotEmpty(indexOfSelectedItem)) {
            Integer index = Integer.valueOf(indexOfSelectedItem);
            System.debug('\'https://praxas.sharepoint.com' +
                                     '/_api/Web/GetFileByServerRelativeUrl(\''+
                                     encodeString(listFolderAndFilesFromSP[index].endpoint)+
                                     '\')/$value\'');
                                     
            createDocumentFromSPFile('https://praxas.sharepoint.com' +
                                     '/_api/Web/GetFileByServerRelativeUrl(\''+
                                     listFolderAndFilesFromSP[index].endpoint+
                                     '\')/$value', index);
        }
        else {
            System.debug('Error occured while retrieving CustomEmailTempAttachment folder');
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING, 'Unexpected error is occured..Please contact your administrator'));
        }
        
    }
    //--Wrapper class to stored files folders attributes
    public class FolderAndFilesFromSP {
        public String Name{get;set;}
        public String lastModifiedDate{get;set;}
        public String endpoint{get;set;}
        public String type{get;set;}
        Integer totalItems;
    }
    
    //--Wrapper class to stored selected Attachment
    public class DocumentWrapper {
        public String id {get;set;}
        public String Name{get;set;}
        Integer size;
        String type;
        
    }
    
    //--Wrapper class to stored authorization parameters
    class AccessDetails {
        String access_token;
    }
}