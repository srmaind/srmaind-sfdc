public with sharing class StaticClass {

    public String inputString {get; set;}

    public static String strStatic = 'Class Level';

    public StaticClass() {
        System.debug(strStatic);
        strStatic = 'Constructor Level';
        System.debug(strStatic);
    }

    public static void getStaticString() {
        System.debug(strStatic);
        //return strStatic;
    }

    public void setStaticStringFromPage() {
        strStatic = inputString;
        System.debug(strStatic);
        // return strStatic;
    }

    public static void setStaticString(String pString) {
        strStatic = pString;
        System.debug(strStatic);
        // return strStatic;
    }

}