public with sharing class StringArrayTest {
    public static List<String> generateStringArray(Integer n) {
        List<String> lstTest = new List<String>();
        for (Integer i = 0; i <= n; i++) {
            lstTest.add('Test ' + n);
        }
        return lstTest;
    }
}