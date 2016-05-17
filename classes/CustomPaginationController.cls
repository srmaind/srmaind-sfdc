/**

 */

public class CustomPaginationController {

    public List<Account> lstAccount {get; set;}
    private Map<Integer,List<Account>> mapRecords;
    private Integer pageNumber;
    private Integer pageSize = 10;
    private Integer pageCount;

    public CustomPaginationController() {
        mapRecords = fetchAccountsMap(pageSize);
        lstAccount = new List<Account>();
        pageNumber = 1;
        lstAccount = mapRecords.get(pageNumber);
    }

    public void next() {
        pageNumber++;
        //lstAccount = populateList(lstRecords, pageNumber, pageSize);
        lstAccount = mapRecords.get(pageNumber);
    }

    public void previous() {
        pageNumber--;
        //lstAccount = populateList(lstRecords, pageNumber, pageSize);
        lstAccount = mapRecords.get(pageNumber);
    }

    static List<Account> populateList(List<Account> lstRecords, Integer pageNumber, Integer pageSize) {
        List<Account> lstAccount = new List<Account>();
        Integer startInt = (pageNumber-1)*pageSize;
        Integer endInt = pageNumber*pageSize;
        for (Integer i=startInt; i<endInt; i++) {
            lstAccount.add(lstRecords[i]);
        }
        return lstAccount;
    }

    static Map<Integer,List<Account>> fetchAccountsMap(Integer pageSize) {
        Map<Integer,List<Account>> mapRecords = new Map<Integer,List<Account>>();
        Integer pageCount = 0;
        Integer recordCounter = 0;
        List<Account> lstAccount = new List<Account>();
        for (Account instAccount : Database.query('SELECT ' + fetchAllFieldsFor('Account') + ' FROM Account ORDER BY Name LIMIT 1000')) {
            lstAccount.add(instAccount);
            recordCounter++;
            if (Math.mod(recordCounter, pageSize) == 0) {
                mapRecords.put(pageCount++, lstAccount);
                lstAccount = new List<Account>();
            }
        }
        if (lstAccount.size() > 0) {
            mapRecords.put(pageCount++, lstAccount);
        }
        return mapRecords;
    }

    static String fetchAllFieldsFor(String objectName) {
        Map<string, Schema.SObjectField> objectFieldsMap = new Map<string, Schema.SObjectField>();
        objectFieldsMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();

        string objectFields = '';
        for (string s : objectFieldsMap.keySet()) {
            if ((objectFieldsMap.get(s).getDescribe().isAccessible())) {
                objectFields += String.escapeSingleQuotes(s);
                objectFields += ',';
            }//End IF
        }//End FOR
        objectFields = objectFields.removeEnd(',');
        return objectFields;
    }

}