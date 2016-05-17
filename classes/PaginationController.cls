public with sharing class PaginationController {

    private static String OBJECT_NAME = 'Account';
    private static String QUERY = 'SELECT Id, Name FROM Account';

    public List<SObject> lstRecord { get; set; }
    public Integer recordCount { get; set; }
    public Integer pageSize { get; set; }
    public Integer pageNumber { get; set; }
    private ApexPages.StandardSetController setController;

    public PaginationController() {
        initialize();
        first();
    }

    private void initialize() {
        pageSize = 10;
        pageNumber = 1;
    }

    public void first() {
        pageNumber = 1;
    }

    private void loadRecords() {
        setController = new ApexPages.StandardSetController(Database.getQueryLocator(QUERY));
        setController.setPageSize(pageSize);
        setController.first();
        lstRecord = setController.getRecords();
    }
}