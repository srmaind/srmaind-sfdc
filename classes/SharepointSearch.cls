public with sharing class SharepointSearch {

    public Integer startIndex                   { get; set; }
    public String endIndex                      { get; set; }
    public String searchText                    { get; set; }
    public List<SearchResultWrapper> lstResult  { get; set; }
    public Integer totalResults                 { get; set; }
    public Integer totalPages                   { get; set; }
    public Integer currentPage                  { get; set; }
    public Boolean hasNext                      { get; set; }
    public Boolean hasPrevious                  { get; set; }
    private static Integer ROW_LIMIT = 10;

    /*public PageReference searchSharePointFiles() {
        getSharePointFiles(0, ROW_LIMIT);
        return null;
    }*/

    public SharepointSearch() {
        lstResult = new List<SearchResultWrapper>();
        totalPages = 0;
        hasPrevious = false;
        hasNext = false;
    }

    public void searchSharePointFiles() {
        if (String.isNotBlank(searchText)) {
            startIndex = 0;
            SharepointSearchResult searchResult = getSharePointFiles(startIndex, ROW_LIMIT);
            if (searchResult != null && searchResult.d != null) {
                lstResult = wrapResults(searchResult);
                currentPage = 1;
                hasPrevious = false;
                if (totalPages == 0 || currentPage == totalPages) {
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

    public void next() {
        if (hasNext) {
            startIndex = startIndex + ROW_LIMIT;
            SharepointSearchResult searchResult = getSharePointFiles(startIndex, ROW_LIMIT);
            lstResult = wrapResults(searchResult);
            currentPage++;
            if (totalPages == 0 || currentPage == 1) {
                hasPrevious = false;
            } else {
                hasPrevious = true;
            }
            if (totalPages == 0 || currentPage == totalPages) {
                hasNext = false;
            } else {
                hasNext = true;
            }
        }
    }

    public void previous() {
        if (hasPrevious) {
            startIndex = startIndex - ROW_LIMIT;
            SharepointSearchResult searchResult = getSharePointFiles(startIndex, ROW_LIMIT);
            lstResult = wrapResults(searchResult);
            currentPage--;
            if (totalPages == 0 || currentPage == totalPages) {
                hasNext = false;
            } else {
                hasNext = true;
            }
            if (totalPages == 0 || currentPage == 1) {
                hasPrevious = false;
            } else {
                hasPrevious = true;
            }
        }
    }

    public void gotoPageNumber() {
        startIndex = (currentPage - 1)  * ROW_LIMIT;
        SharepointSearchResult searchResult = getSharePointFiles(startIndex, ROW_LIMIT);
        lstResult = wrapResults(searchResult);
        if (totalPages == 0 || currentPage == 1) {
            hasPrevious = false;
        } else {
            hasPrevious = true;
        }
        if (totalPages == 0 || currentPage == totalPages) {
            hasNext = false;
        } else {
            hasNext = true;
        }
    }

    public SharepointSearchResult getSharePointFiles(Integer startRow, Integer rowlimit) {
        SharepointController sp = new SharepointController();
        //String accessToken1 = sp.getAccessToken();
        String accessToken1 = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsIng1dCI6Ik1uQ19WWmNBVGZNNXBPWWlKSE1iYTlnb0VLWSJ9.eyJhdWQiOiIwMDAwMDAwMy0wMDAwLTBmZjEtY2UwMC0wMDAwMDAwMDAwMDAvcHJheGFzLnNoYXJlcG9pbnQuY29tQDYyZWVmZmE5LTdiYTItNDc5MS05YzdlLWQ1NGQzNWY0MDQyMyIsImlzcyI6IjAwMDAwMDAxLTAwMDAtMDAwMC1jMDAwLTAwMDAwMDAwMDAwMEA2MmVlZmZhOS03YmEyLTQ3OTEtOWM3ZS1kNTRkMzVmNDA0MjMiLCJuYmYiOjE0NTU5NjA4MzksImV4cCI6MTQ1NjAwNDAzOSwibmFtZWlkIjoiMTAwMzdmZmU5NTAwNWZhMiIsImFjdG9yIjoiYTdjY2I1MWMtYjE3NS00ZTBmLTgwNjQtNzNmODA5M2RmYTMzQDYyZWVmZmE5LTdiYTItNDc5MS05YzdlLWQ1NGQzNWY0MDQyMyIsImlkZW50aXR5cHJvdmlkZXIiOiJ1cm46ZmVkZXJhdGlvbjptaWNyb3NvZnRvbmxpbmUifQ.DLZ18jMq0PQ3ldBPm88xE0e5g2bxerf-wgJ5Mv9SKPe64tKBsrFiw55t8hb74oj4syld85bNwvmMVoTCbNOHTp43vShNBellfINVrzCD5lCw0rP7-2_jZHJmN_GyoxSB5oMyPQseKn6spo2a3f1QJ0kCIrhj_MOsS5c03MhAEokhMMtMXy7FCEDh039WTPwVk-ZTQ4aqLaa6a3x_ginBYY9VRY4KvDOZlYqJr1PgZ_UxuPWGss3D2jpSesqQ-GhUhe20uyj3j8wWEvhhyviNrRFfC72nkMkm3TK1TcDQhZ4zsOzTa67KqOpq8itm9TLaSVxTMxUnf_8GFtmi8wMJbg';
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://praxas.sharepoint.com/_api/search/query?'
                        + 'querytext=\'' + searchText
                        + '\'&startrow=' + startrow
                        + '&rowlimit=' + rowlimit
                        + '&selectproperties='
                        + '\'Title,Path,ServerRedirectedPreviewURL,FileExtension,LastModifiedTime\'');
        system.debug('Endpoint URL = ' + req.getEndpoint());
        String accessToken = 'Bearer '+accessToken1;
        req.setHeader('Authorization', accessToken);
        req.setHeader('Accept','application/json;odata=verbose');
        req.setMethod('GET');
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        
        System.debug('result = ' + res.getBody());
        
        SharepointSearchResult searchDetails;
        try {
            searchDetails = (SharepointSearchResult)JSON.deserialize(res.getBody(), SharepointSearchResult.class);
            System.debug('response of search result::' + searchDetails);
            if (searchDetails != null && searchDetails.d != null) {
                totalResults = searchDetails.d.query.PrimaryQueryResult.RelevantResults.TotalRows;
                totalPages = (Integer) Math.ceil(Decimal.valueOf(totalResults) / Decimal.valueOf(ROW_LIMIT)); 
                system.debug('totalPages = ' + totalPages);
            }
        } catch (System.JsonException jsonExcp) {
            System.debug('JSON Exception Occurred while deserializing result body : ' + jsonExcp);
        }
        
        return searchDetails;
    }

    public List<SearchResultWrapper> wrapResults(SharepointSearchResult searchResults) {
        List<SearchResultWrapper> lstSearchResultWrapper = new List<SearchResultWrapper>();

        try {
            for (SharepointSearchResult.Results_Y searchResult : 
                    searchResults.d.query.PrimaryQueryResult.RelevantResults.Table.Rows.results) {
                SearchResultWrapper resultWrapper = new SearchResultWrapper();
                for (SharepointSearchResult.Results_Z property : searchResult.Cells.results) {
                    if (property.Key.equalsIgnoreCase('Title')) {
                        resultWrapper.title = property.Value;
                    }
                    if (property.Key.equalsIgnoreCase('Path')) {
                        resultWrapper.path = property.Value;
                    }
                    if (String.isNotBlank(resultWrapper.title) && String.isNotBlank(resultWrapper.path)) {
                        break;
                    }
                }
                lstSearchResultWrapper.add(resultWrapper);
            }
        } catch(System.Exception excp) {
            system.debug('Exception occurred while wrapping search results : ' + excp);
        }

        return lstSearchResultWrapper;
    }

    public class SearchResultWrapper {
        public String title { get; set; }
        public String path  { get; set; }

        public SearchResultWrapper() {
            title = '';
            path = '';
        }
    }
}