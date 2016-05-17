public with sharing class Pagination {
    Public Integer noOfRecords{get; set;}
    Public Integer size{get;set;}
    public List<Account> Accounts {get;set;}
    public ApexPages.StandardSetController setCon {get;set;}

    public Pagination() {
        initSetCon();
        Accounts = (List<Account>)setCon.getRecords();
    }

    public void initSetCon() {
        if(setCon == null) {
            size = 50;
            string queryString = 'Select Name, Type, BillingCity, BillingState, BillingCountry from Account order by Name';
            setCon = new ApexPages.StandardSetController(Database.getQueryLocator(queryString));
            setCon.setPageSize(size);
            noOfRecords = setCon.getResultSize();
        }
    }

    // Public List<Account> getAccounts() {
        // List<Account> accList = new List<Account>();
        // for(Account a : (List<Account>)setCon.getRecords())
        //     accList.add(a);
    //     return (List<Account>)setCon.getRecords();
    // }

    public pageReference refresh() {
        setCon = null;
        initSetCon();
        setCon.setPageNumber(1);
        Accounts = (List<Account>)setCon.getRecords();
        return null;
    }

    public Boolean hasNext {
        get {
            return setCon.getHasNext();
        }
        set;
    }
    public Boolean hasPrevious {
        get {
            return setCon.getHasPrevious();
        }
        set;
    }

    public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
    }

    public void first() {
        setCon.first();
        Accounts = (List<Account>)setCon.getRecords();
    }

    public void last() {
        setCon.last();
        Accounts = (List<Account>)setCon.getRecords();
    }

    public void previous() {
        setCon.previous();
        Accounts = (List<Account>)setCon.getRecords();
    }

    public void next() {
        setCon.next();
        Accounts = (List<Account>)setCon.getRecords();
    }
}