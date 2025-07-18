public class GenerateInvoiceId {
    
    public static String generateInvoiceId(String company, String centre, String product, String invoiceNumber) {
        
        Date currentDate = Date.today();
       	Integer currentYear = currentDate.year();
        Integer currentMonth = currentDate.month(); 

        Integer financialYear = (currentMonth >= 4) ? currentYear : (currentYear - 1);
        String formattedYear = String.valueOf(financialYear).right(2); 
        
        // You can replace the number generation logic as per your requirements
        //String invoiceNumber = '000001';
        invoiceNumber = invoiceNumber.leftPad(6, '0');
        System.debug('invoiceNumber1===>'+invoiceNumber);
        if (invoiceNumber.length() > 6) {
            invoiceNumber = invoiceNumber.substring(invoiceNumber.length() - 6);
            System.debug('invoiceNumber2===>'+invoiceNumber);
        }
        
        //Concatenate all parts to form the final Invoice ID
        //Commented the below invoice id format based on Finance team request (Biswa) Modified :14/10/2024 Developer : Prathap
        //String invoiceId = company + centre + formattedYear + formattedMonth + product + invoiceNumber;
        
        //String invoiceId = company + centre + '25' + invoiceNumber;
        
        //Added By Ram
        String invoiceId = company + centre + formattedYear + invoiceNumber;
        
		System.debug('invoiceId===>'+invoiceId);
        
        return invoiceId;
    }
    
}