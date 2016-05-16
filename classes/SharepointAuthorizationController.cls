public with sharing class SharepointAuthorizationController {

    public PageReference getCodeParam() {
        
        try
        {
            SharepointAuthorization__c sharepointAuth = new SharepointAuthorization__c();
            
            sharepointAuth = [ SELECT Client_Id__c,
                                      Redirect_URI__c,
                                      audience_principal_ID__c, 
                                      Bearer_realm__c,
                                      Client_Secret__c,
                                      Site__c
                               FROM SharepointAuthorization__c LIMIT 1];
            
            
            String urlToGetCodeParam = 'https://'+ sharepointAuth.Site__c +'/_layouts/15/OAuthAuthorize.aspx?client_id='+sharepointAuth.Client_Id__c+
                                       '&scope=Web.Read%20List.Write&response_type=code&'+
                                       'redirect_uri='+sharepointAuth.Redirect_URI__c;
                                                               
            PageReference sharepointLoginPage = new PageReference(urlToGetCodeParam);
            
            return sharepointLoginPage;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Exception Occured while retrieving code'+e.getMessage()));
            return null;
        }
    }
    
    
    public void saveAccessToken()
    {
        try
        {
            SharepointAuthorization__c sharepointAuth = new SharepointAuthorization__c();
            
            sharepointAuth = [ SELECT Client_Id__c,
                                          Redirect_URI__c,
                                          audience_principal_ID__c, 
                                          Bearer_realm__c,
                                          Client_Secret__c,
                                          Site__c
                                   FROM SharepointAuthorization__c LIMIT 1];
                                   
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://accounts.accesscontrol.windows.net/'+
                            sharepointAuth.Bearer_realm__c+
                            '/tokens/OAuth/2');
                            
            req.setMethod('POST');
            
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setHeader('Accept','application/json;odata=verbose');
            String reqBody = 'grant_type=authorization_code' +
                             '&client_id='+sharepointAuth.Client_Id__c+
                             EncodingUtil.URLENCODE('@','UTF-8')+
                             +sharepointAuth.Bearer_realm__c+
                             '&client_secret='+EncodingUtil.URLENCODE(sharepointAuth.Client_Secret__c,'UTF-8')+
                             '&code='+ApexPages.currentPage().getParameters().get('code')+
                             '&redirect_uri='+EncodingUtil.URLENCODE(sharepointAuth.Redirect_URI__c,'UTF-8')+
                             '&resource='+sharepointAuth.audience_principal_ID__c+EncodingUtil.URLENCODE('/','UTF-8')+
                             sharepointAuth.Site__c+EncodingUtil.URLENCODE('@','UTF-8')+
                             sharepointAuth.Bearer_realm__c;
            System.debug('Req Body::'+reqBody);                 
            req.setBody(reqBody);
            
            Http http = new Http();
            HTTPResponse res = http.send(req);
            
            AuthenticationParam authParameters = (AuthenticationParam)JSON.deserialize(res.getBody(), AuthenticationParam.class);
            System.debug('resfreshtoken::'+authParameters.refresh_token);
            
            sharepointAuth.Refresh_Token__c = authParameters.refresh_token;
        
            update sharepointAuth;
        } catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error,'Exception Occured while retrieving refresh token'+e.getMessage()));    
        }
    }
    
    class AuthenticationParam
    {
        String refresh_token;
    }
}