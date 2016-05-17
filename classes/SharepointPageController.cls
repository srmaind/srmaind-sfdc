public with sharing class SharepointPageController 
{
    public String listDocumentWrapperJsonStr { get; set; }
    String accessToken;
    SharepointAuthorization__c sharepointAuth;
    public List<FolderAndFilesFromSP> listFolderAndFilesFromSP{get;set;}
    List<DocumentWrapper> listdocWrapper;
    String parent;
    public Integer itemCount {get;set;}
    public Integer displayedItemCount{get;set;}
    public Integer folderItemCount{get;set;}
    public Integer recordLimit{get;set;}
    public Integer fileOffset;
    public Integer startIndex {get;set;}
    public Integer lastIndex {get;set;}
    
    public SharepointPageController()
    {
        startIndex = null;
        itemCount =0;
        recordLimit = 15;
        folderItemCount = 0;
        displayedItemCount = 0;
        fileOffset = 0;
        listdocWrapper = new List<DocumentWrapper>();
        listFolderAndFilesFromSP = new List<FolderAndFilesFromSP>();
        accessToken = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik1uQ19WWmNBVGZNNXBPWWlKSE1iYTlnb0VLWSJ9.eyJhdWQiOiIwMDAwMDAwMy0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDAvcHJheGFzLnNoYXJlcG9pbnQuY29tQDYyZWVmZmE5LTdiYTItNDc5MS05YzdlLWQ1NGQzNWY0MDQyMyIsImlzcyI6IjAwMDAwMDAxLTAwMDAtMDAwMC1jMDAwLTAwMDAwMDAwMDAwMEA2MmVlZmZhOS03YmEyLTQ3OTEtOWM3ZS1kNTRkMzVmNDA0MjMiLCJuYmYiOjE0NTQ2MTUzNTYsImV4cCI6MTQ1NDY1ODU1NiwibmFtZWlkIjoiMTAwMzdmZmU5NTAwNWZhMiIsImFjdG9yIjoiYTdjY2I1MWMtYjE3NS00ZTBmLTgwNjQtNzNmODA5M2RmYTMzQDYyZWVmZmE5LTdiYTItNDc5MS05YzdlLWQ1NGQzNWY0MDQyMyIsImlkZW50aXR5cHJvdmlkZXIiOiJ1cm46ZmVkZXJhdGlvbjptaWNyb3NvZnRvbmxpbmUifQ.i1wwixRnzNcuIBVqK6EIQgpTueMeQQdLUXvDX0Z7Nu1A7DRFUnHDvAagXgsDbIaj14UBbfx_SZREH3VqIvOiOIzGsyuuJf0UpQcL2SlX0gOOxwxwez9IJ7c9LLXD_Yiij23N1EZV2tEgiI6n1G-s9Fel2D6wfk7ZqLWE2sPgLUtLMQLQrrG9d7cw3KI1oZyuuHy5Kue8CwI-kYfp0umOUeoL4f5OQVG2yS9CpSUA9o14l4IX5jqQPAfCdu8Dbf2rq6m15wLaT1qWVs4raYS_Y7b2l4iJYIgJSqGwwECp6GBoG0_jOMnircThTQx6-Gsgo-wCNLib3LsuUob0Qa3eww';
        //System.debug('Access Token::'+accessToken);
        
    }
    
    String getAccessToken()
    {
        try
        {
            SharepointAuthorization__c sharepointAuth = new SharepointAuthorization__c();
            
            sharepointAuth = [ SELECT Client_Id__c,
                                      Redirect_URI__c,
                                      audience_principal_ID__c, 
                                      Bearer_realm__c,
                                      Client_Secret__c,
                                      Refresh_Token__c,
                                      Site__c
                               FROM SharepointAuthorization__c LIMIT 1];
                                   
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
            System.debug('Req Body::'+reqBody);                 
            req.setBody(reqBody);
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            SharepointPageController.AccessDetails accessDetails = (SharepointPageController.AccessDetails)JSON.deserialize(res.getBody(), SharepointPageController.AccessDetails.class);
            System.debug('Access-token::'+accessDetails.access_token);
            
            return accessDetails.access_token;
            
        } catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Exception Occured while retrieving access token'+e.getMessage()));
            return '';   
        }
    
    }
    
    public void browseSharedDocuments()
    {
        try
        {
            sharepointAuth = [ SELECT Client_Id__c,
                                      Redirect_URI__c,
                                      audience_principal_ID__c, 
                                      Bearer_realm__c,
                                      Client_Secret__c,
                                      Refresh_Token__c,
                                      Site__c
                               FROM SharepointAuthorization__c LIMIT 1];
            
            itemCount = 0;
            folderItemCount = getItemCountOfParentDirectory();
            System.debug('parent folderCount::'+folderItemCount);
            getFolders('https://'+sharepointAuth.Site__c+'/_api/Web/GetFolderByServerRelativeUrl(\'/Gedeelde%20%20documenten\')');
            
            listFolderAndFilesFromSP.remove(0);
            displayedItemCount = listFolderAndFilesFromSP.size();
        } catch(Exception e)
        {
            System.debug('Exception occured while retrieving authorization parameters!!'+e.getMessage());
        }
        
    }
    
    Integer getItemCountOfParentDirectory()
    {
        try
        {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://'+sharepointAuth.Site__c+'/_api/Web/GetFolderByServerRelativeUrl(\'/Gedeelde%20%20documenten\')/ItemCount');
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer '+accessToken);
            req.setHeader('Accept','application/json;odata=verbose');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug('Response::'+res.getBody());
            map<String, Map<String, String>> mapFolderToItemCount =  (map<String, Map<String, String>>)JSON.deserialize(res.getBody(), map<String, Map<String, String>>.class);
            return Integer.valueof(mapFolderToItemCount.get('d').get('ItemCount'));
        }
        catch(Exception e)
        {
            System.debug('Error occured while retrieving item Count Of Parent Directory');
            return 0;
        }
    }
    
    public void  getFolders()
    {
        itemCount =0;
        folderItemCount = 0;
        displayedItemCount = 0;
        fileOffset = 0;
        Integer index = Integer.valueOf(Apexpages.currentPage().getParameters().get('listIndex'));
        
        
        if(listFolderAndFilesFromSP[index].Name.equals('...'))
        {
            
            String parentURL = getParentOfCurrentDirectory(listFolderAndFilesFromSP[index].endpoint+'/parentfolder?$select=__metadata');
            
            /*System.debug('url for debug'+'https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       parentURL+
                       ')');*/
            getFolders('https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       parentURL+
                       ')');
        }
        else if(! listFolderAndFilesFromSP[index].type.equals('SP.File'))
        {
        
            parent = listFolderAndFilesFromSP[index].endpoint;
            folderItemCount = listFolderAndFilesFromSP[index].itemCount;
            System.debug('url form:::'+'https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       listFolderAndFilesFromSP[index].endpoint+
                       ')');
            getFolders('https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       listFolderAndFilesFromSP[index].endpoint+
                       ')');
        }
        else
        {
            parent = listFolderAndFilesFromSP[index].endpoint;
            createDocumentFromSPFile('https://'+sharepointAuth.Site__c +
                                     '/_api/Web/GetFileByServerRelativeUrl('+
                                     listFolderAndFilesFromSP[index].endpoint+
                                     ')/$value');
        }
        System.debug('parent::'+parent);
    }
    
    String getParentOfCurrentDirectory(String endPoint)
    {
        try
        {
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
        } catch(Exception e)
        {
            System.debug('Exception occured while retrieving parent::'+e.getMessage());
            return null;
        }
                    
    }
    
    void getFolders(String endPoint)
    {
        //--Create instance to trace immidiate parent
        System.debug('endpoint in get folder::'+endPoint);
        system.debug('startIndex = ' + startIndex);
        system.debug('itemCount = ' + itemcount);
        system.debug('listFolderAndFilesFromSP.size() = ' + listFolderAndFilesFromSP.size());
        system.debug('folderItemCount = ' + folderItemCount);
        system.debug('displayedItemCount = ' + displayedItemCount);
        listFolderAndFilesFromSP = new List<FolderAndFilesFromSP>();
        
        startIndex = null;
        
        FolderAndFilesFromSP fileFromSP = new FolderAndFilesFromSP();
        fileFromSP.type             = 'SP.Folder';
        fileFromSP.Name             = '...';
        fileFromSP.endpoint         = endPoint;
        
        listFolderAndFilesFromSP.add(fileFromSP);
        
        SharepointDTO spDTO = callSharepointService(endPoint+'/folders?$select=Name,TimeLastModified,itemcount&$filter=itemcount%20gt%200&$skip='+itemCount+'&$top='+recordLimit);
        System.debug('spDTO::'+spDTO);
        System.debug('Get folder enpoint::'+endPoint+'/folders?$select=Name,TimeLastModified');
        if(spDTO.d != null)
        { 
            buildSPDTO(spDTO);
            if(listFolderAndFilesFromSP.size() > 1)
            {
                system.debug('itemCount = ' + itemcount);
                startIndex = itemCount;
                displayedItemCount += listFolderAndFilesFromSP.size()-1;
                //itemCount = displayedItemCount;
                itemCount += listFolderAndFilesFromSP.size()-1;
            } 
        }
        
        system.debug('listFolderAndFilesFromSP between = ' + listFolderAndFilesFromSP.size());
        
        if(listFolderAndFilesFromSP.size() - 1 < recordLimit)
        {
            System.debug('fileOffset::'+fileOffset);
            Integer listFolderSize = (listFolderAndFilesFromSP.size() == 1) ? 0:itemCount;
            spDTO = callSharepointService(endPoint + '/files?$select=Name,TimeLastModified,ContentType&$skip='+fileOffset + '&$top=' + Math.abs(recordLimit - listFolderSize));
            System.debug('file count::'+spDTO.d.results.size());
            if(spDTO.d != null)
            {
                buildSPDTO(spDTO);
            }
            if(listFolderAndFilesFromSP.size() > 1)
            {
                system.debug('fileOffset = ' + fileOffset);
                if (startIndex == null) {
                    startIndex = fileOffset;
                    itemCount += listFolderAndFilesFromSP.size()-1;
                }
                fileOffset +=  spDTO.d.results.size();
                displayedItemCount +=  Math.abs((listFolderAndFilesFromSP.size() - 1) - listFolderSize);
            }
        }    
        Integer quotient = Math.mod(folderItemCount,recordLimit);
        lastIndex = ((Integer)((folderItemCount-recordLimit)/recordLimit)) * recordLimit;
        system.debug('lastIndex after = ' + lastIndex);
        system.debug('startIndex after = ' + startIndex);
        system.debug('itemCount after = ' + itemcount);
        system.debug('listFolderAndFilesFromSP.size() after = ' + listFolderAndFilesFromSP.size());
        system.debug('folderItemCount after = ' + folderItemCount);
        system.debug('displayedItemCount after = ' + displayedItemCount);
    }
    
    void getPreviousFolders(String endPoint)
    {
        //--Create instance to trace immidiate parent
        System.debug('endpoint in get folder::'+endPoint);
        system.debug('itemCount = ' + itemcount);
        system.debug('listFolderAndFilesFromSP.size() = ' + listFolderAndFilesFromSP.size());
        system.debug('folderItemCount = ' + folderItemCount);
        system.debug('displayedItemCount = ' + displayedItemCount);
        itemCount = itemCount - listFolderAndFilesFromSP.size();
        itemCount -= 2;
        
        startIndex = null;
        
        listFolderAndFilesFromSP = new List<FolderAndFilesFromSP>();
        
        FolderAndFilesFromSP fileFromSP = new FolderAndFilesFromSP();
        fileFromSP.type             = 'SP.Folder';
        fileFromSP.Name             = '...';
        fileFromSP.endpoint         = endPoint;
        
        listFolderAndFilesFromSP.add(fileFromSP);
        
        SharepointDTO spDTO = callSharepointService(endPoint+'/folders?$select=Name,TimeLastModified,itemcount&$filter=itemcount%20gt%200&$skip='+itemCount+'&$top='+recordLimit);
        System.debug('spDTO::'+spDTO);
        System.debug('Get folder enpoint::'+endPoint+'/folders?$select=Name,TimeLastModified');
        if(spDTO.d != null)
        { 
            buildSPDTO(spDTO);
            if(listFolderAndFilesFromSP.size() > 1)
            {
                startIndex = itemCount;
                displayedItemCount += listFolderAndFilesFromSP.size()-1;
                //itemCount = displayedItemCount;
                itemCount += listFolderAndFilesFromSP.size()-1;
            } 
        }
        
        if(listFolderAndFilesFromSP.size() - 1 < recordLimit)
        {
            System.debug('fileOffset::'+fileOffset);
            Integer listFolderSize = (listFolderAndFilesFromSP.size() == 1) ? 0:itemCount;
            spDTO = callSharepointService(endPoint + '/files?$select=Name,TimeLastModified,ContentType&$skip='+fileOffset + '&$top=' + Math.abs(recordLimit - listFolderSize));
            System.debug('file count::'+spDTO.d.results.size());
            if(spDTO.d != null)
            {
                buildSPDTO(spDTO);
            }
            if(listFolderAndFilesFromSP.size() > 1)
            {
                if (startIndex == null) {
                    startIndex = fileOffset;
                    itemCount += listFolderAndFilesFromSP.size()-1;
                }
                fileOffset +=  spDTO.d.results.size();
                displayedItemCount +=  Math.abs((listFolderAndFilesFromSP.size() - 1) - listFolderSize);
            }
        }    
        system.debug('itemCount after = ' + itemcount);
        system.debug('listFolderAndFilesFromSP.size() after = ' + listFolderAndFilesFromSP.size());
        system.debug('folderItemCount after = ' + folderItemCount);
        system.debug('displayedItemCount after = ' + displayedItemCount);
    }
    
    void buildSPDTO(SharepointDTO spDTO)
    {
        for(SharepointDTO.ResponseFromSP folder : spDTO.d.results)
        {
            FolderAndFilesFromSP fileFromSP = new FolderAndFilesFromSP();
            fileFromSP.type             = folder.metadata.type;
            fileFromSP.Name             = folder.Name;
            fileFromSP.endpoint         = folder.metadata.uri.substringBetween('(', ')');
            fileFromSP.lastModifiedDate = folder.TimeLastModified.format('dd/MM/yyyy');
            fileFromSP.itemCount        = folder.itemCount;
            //Date.valueOf(folder.TimeLastModified);
            
            listFolderAndFilesFromSP.add(fileFromSP);
        }
            
    }
    
    SharepointDTO callSharepointService(String endPoint)
    {
        try
        {
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
        } catch(Exception e)
        {
            System.debug('Exception occured while retrieving folders or files from Sharepoint::'+e.getMessage());
            return null;
        }
    }
    
    void createDocumentFromSPFile(String endpoint)
    {
        try
        {
            Integer index = Integer.valueOf(Apexpages.currentPage().getParameters().get('listIndex'));
            Folder folder = [ SELECT Id FROM Folder WHERE Name = :'CustomEmailTempAttachment'];  
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer '+accessToken);
            req.setHeader('binaryStringResponseBody','true');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            System.debug('Response::'+res.getBody());
            
            Document document = new Document();
            document.Name = listFolderAndFilesFromSP[index].name;
            document.body = res.getBodyAsBlob();
            document.folderId = folder.id;
            
            insert document;
            
            if(document.id != null)
            {
                DocumentWrapper docWrapper = new DocumentWrapper();
                docWrapper.id = document.id;
                docWrapper.name = document.name;
                docWrapper.size = document.BodyLength;
                docWrapper.type = 'Document';
                listdocWrapper.add(docWrapper);
                listDocumentWrapperJsonStr = json.serialize(listdocWrapper);
                
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Info,'Attachment created successfully...'));
            }
            else
            {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error while creating attachment...Please try again or contact your administrator'));    
            }
        } catch(Exception e)
        {
            System.debug('Exception occured while inserting document::'+e.getMessage());
        }
    }
    
    
    public PageReference getNextFoldersAndFiles() 
    { 
        
        //if(displayedItemCount < folderItemCount)
        //{
         
            System.debug('url form:::'+'https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       parent+
                       ')');
            getFolders('https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       parent+
                       ')');
            //folderItemCount = folderItemCount - displayedItemCount;
        //}
        return null;
    }
    
    public PageReference getPreviousFoldersAndFiles() 
    { 
        
        //if(displayedItemCount < folderItemCount)
        //{
         
            System.debug('url form:::'+'https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       parent+
                       ')');
            getPreviousFolders('https://'+sharepointAuth.Site__c +
                       '/_api/Web/GetFolderByServerRelativeUrl('+
                       parent+
                       ')');
            //folderItemCount = folderItemCount - displayedItemCount;
        //}
        return null;
    }

    
    public class FolderAndFilesFromSP
    {
        public String Name{get;set;}
        public String lastModifiedDate{get;set;}
        String endpoint;
        String type;
        Integer itemCount;
    }
    
    public class DocumentWrapper
    {
        String id;
        String Name;
        Integer size;
        String type;
        
    }
    
    class AccessDetails
    {
        String access_token;
    }
}