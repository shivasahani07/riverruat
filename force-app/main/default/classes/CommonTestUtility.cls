public class CommonTestUtility {
    public static Account createAccount(String name, String typeofAcc, String centercode,String phone){
         Account accrecord = new Account(
            Name = name,
            Type = typeofAcc,
            Center_Code__c = centercode,
            Phone = phone
        );
        insert accrecord;
        return accrecord;
    }
   
     
}