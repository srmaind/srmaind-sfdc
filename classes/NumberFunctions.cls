public with sharing class NumberFunctions {
    public static List<Integer> exponentArray(Integer n) {
        List<Integer> lstInteger = new List<Integer>();
        if (n > 0) {
            for (Integer i=1; i<n; i++) {
                if (i*i < n) {
                    lstInteger.add(i*i);
                } else {
                    break;
                }
            }
        }
        return lstInteger;
    }

     public static Integer getEvenFibonacciSum(Integer n) {
         Integer i = 1;
         Integer n1 = 0;
         Integer n2 = 1;
         Integer fibonacciSum = 0;
         Integer evenSum = 0;
         while(evenSum <= 5000000) {
             fibonacciSum = n1 + n2;
             n1 = n2;
             n2 = fibonacciSum;
             if (Math.mod(fibonacciSum, 2) ==  0 && Math.mod(i, 2) == 0){
                 evenSum += fibonacciSum;
             }
             i++;
         }
         return evenSum;
    }
}