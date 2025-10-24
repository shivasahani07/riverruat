public without sharing class VINCutOffManagement {
    
    private static final Map<String, Integer> YEAR_CODE_MAP = new Map<String, Integer>{
         'R' => 2024,'S' => 2025,'T' => 2026,'V' => 2027,'W' => 2028,
         'X' => 2029,'Y' => 2030,'A' => 2031,'B' => 2032,'C' => 2033,
         'D' => 2034,'E' => 2035,'F' => 2036,'G' => 2037,'H' => 2038,
         'J' => 2039,'K' => 2040,'L' => 2041,'M' => 2042,'N' => 2043,
         '1' => 2044,'2' => 2045,'3' => 2046,'4' => 2047,'5' => 2048,
         '6' => 2049,'7' => 2050,'8' => 2051,'9' => 2052,'P' => 2053
    };

    private static final Map<String, Integer> MONTH_CODE_MAP = new Map<String, Integer>{
        'A' => 1,'B' => 2,'C' => 3,'D' => 4,'E' => 5,'F' => 6,
        'G' => 7,'H' => 8,'J' => 9,'K' => 10,'L' => 11,'M' => 12
    };
        
    public static final Integer INVALID_RESULT = -99;
    
    public class ComparisonResult {
        @AuraEnabled public Integer resultCode;
        @AuraEnabled public String message;
        @AuraEnabled public Boolean isSuccess;
        
        public ComparisonResult(Integer code, String msg, Boolean success) {
            resultCode = code;
            message = msg;
            isSuccess = success;
        }
    }
    
    

    @AuraEnabled
    public static ComparisonResult compareVINFormat(String preVIN, String postVIN) {
        try {
            if (String.isBlank(preVIN) || String.isBlank(postVIN)) {
                return new ComparisonResult(INVALID_RESULT, 'VIN values cannot be empty', false);
            }

            if (preVIN.length() < 8 || postVIN.length() < 8) {
                return new ComparisonResult(INVALID_RESULT, 'VIN must be at least 8 characters long', false);
            }

            // Get last 8 chars
            String preLast8  = preVIN.right(8).toUpperCase().trim();
            String postLast8 = postVIN.right(8).toUpperCase().trim();

            // Extract month/year characters
            String preMonthChar  = preLast8.substring(0,1);
            String preYearChar   = preLast8.substring(1,2);
            String postMonthChar = postLast8.substring(0,1);
            String postYearChar  = postLast8.substring(1,2);

            // Map year
            Integer preYear  = YEAR_CODE_MAP.get(preYearChar);
            Integer postYear = YEAR_CODE_MAP.get(postYearChar);
            if (preYear == null || postYear == null) {
                return new ComparisonResult(INVALID_RESULT, 'Unknown year code in VIN', false);
            }

            // Compare years
            if (postYear > preYear) return new ComparisonResult(1, 'Post VIN year is newer', true);
            if (postYear < preYear) return new ComparisonResult(-1, 'Post VIN year is older', true);

            // Same year → compare month
            Integer preMonth  = MONTH_CODE_MAP.get(preMonthChar);
            Integer postMonth = MONTH_CODE_MAP.get(postMonthChar);
            if (preMonth == null || postMonth == null) {
                return new ComparisonResult(INVALID_RESULT, 'Unknown month code in VIN', false);
            }

            if (postMonth > preMonth) return new ComparisonResult(1, 'Post VIN month is newer', true);
            if (postMonth < preMonth) return new ComparisonResult(-1, 'Post VIN month is older', true);

            // Same year & month → compare remaining sequence
            String preSeq  = preLast8.substring(2);
            String postSeq = postLast8.substring(2);

            String preDigits  = preSeq.replaceAll('[^0-9]', '');
            String postDigits = postSeq.replaceAll('[^0-9]', '');

            if (!String.isBlank(preDigits) && !String.isBlank(postDigits)) {
                Long preNum  = Long.valueOf(preDigits);
                Long postNum = Long.valueOf(postDigits);

                if (postNum > preNum) return new ComparisonResult(1, 'Post VIN sequence is higher', true);
                if (postNum < preNum) return new ComparisonResult(-1, 'Post VIN sequence is lower', true);
                return new ComparisonResult(0, 'VINs are identical', true);
            }

            // Fallback: lexicographic compare
            Integer lex = postSeq.compareTo(preSeq);
            if (lex > 0) return new ComparisonResult(1, 'Post VIN is lexicographically greater', true);
            if (lex < 0) return new ComparisonResult(-1, 'Post VIN is lexicographically smaller', true);
            return new ComparisonResult(0, 'VINs are identical', true);

        } catch (Exception e) {
            return new ComparisonResult(INVALID_RESULT, 'Error comparing VINs: ' + e.getMessage(), false);
        }
    }
    
    @AuraEnabled
    public static ComparisonResult validateVIN(String vin) {
        try {
            if (String.isBlank(vin)) {
                return new ComparisonResult(INVALID_RESULT, 'VIN cannot be empty', false);
            }

            if (vin.length() < 8) {
                return new ComparisonResult(INVALID_RESULT, 'VIN must be at least 8 characters long', false);
            }

            String last8 = vin.right(8).toUpperCase().trim();
            String yearChar = last8.substring(1,2);
            String monthChar = last8.substring(0,1);

            // Check if year code is valid
            if (!YEAR_CODE_MAP.containsKey(yearChar)) {
                return new ComparisonResult(INVALID_RESULT, 'Invalid year code in VIN', false);
            }

            // Check if month code is valid
            if (!MONTH_CODE_MAP.containsKey(monthChar)) {
                return new ComparisonResult(INVALID_RESULT, 'Invalid month code in VIN', false);
            }

            return new ComparisonResult(0, 'VIN format is valid', true);
        } catch (Exception e) {
            return new ComparisonResult(INVALID_RESULT, 'Error validating VIN: ' + e.getMessage(), false);
        }
    }
}