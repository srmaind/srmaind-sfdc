public class Batch implements Database.Batchable<SObject>{

    public List<String> setStr;
    
    public List<Account> lstAccount;

    public Batch(List<String> pSet) {
        init();
        setStr = pSet;
        setStr.add('wasd');
    }
    
    public Batch(List<Account> pLstAccount) {
        init();
        lstAccount = pLstAccount;
    }
    
    public void init() {
        setStr = new List<String>();
        setStr.add('wasd');
        lstAccount = new List<Account>();
    }
    
    public List<Account> start(Database.BatchableContext BC) {
        //String query = ' SELECT    Id ' +
            //' , Name ' +
            //' FROM      Account LIMIT 5';
        return lstAccount;
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope) {
        setStr.add('WASD');
    }
    
    public void finish(Database.BatchableContext BC) {
            System.debug('Set = ' + setStr);
        System.debug('Set size = ' + setStr.size());
    }
}