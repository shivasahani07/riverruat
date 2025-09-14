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

    // Special return for invalid cases
    public static final Integer INVALID_RESULT = -99;

    /*
     * Compare two VINs according to year & month codes (found in the last 8 chars).
     * Returns:
     *   1   → postVIN > preVIN
     *   0   → postVIN == preVIN
     *  -1   → postVIN < preVIN
     *  -99  → invalid input / unrecognized codes
     */
    public static Integer compareVINFormat(String preVIN, String postVIN) {
        try {
            System.debug('preVIN : ' + preVIN);
            System.debug('postVIN : ' + postVIN);
            
            if (String.isBlank(preVIN) || String.isBlank(postVIN)) {
                return INVALID_RESULT;
            }

            if (preVIN.length() < 8 || postVIN.length() < 8) {
                System.debug('VIN too short!');
                return INVALID_RESULT;
            }

            // Get last 8 chars
            String preLast8  = preVIN.right(8).toUpperCase().trim();
            String postLast8 = postVIN.right(8).toUpperCase().trim();
            System.debug('preLast8 : ' + preLast8);
            System.debug('postLast8 : ' + postLast8);

            // Extract month/year characters
            String preMonthChar  = preLast8.substring(0,1);
            String preYearChar   = preLast8.substring(1,2);
            String postMonthChar = postLast8.substring(0,1);
            String postYearChar  = postLast8.substring(1,2);

            // Map year
            Integer preYear  = YEAR_CODE_MAP.get(preYearChar);
            Integer postYear = YEAR_CODE_MAP.get(postYearChar);
            if (preYear == null || postYear == null) {
                System.debug('Unknown year code!');
                return INVALID_RESULT;
            }

            // Compare years
            if (postYear > preYear) return 1;
            if (postYear < preYear) return -1;

            // Same year → compare month
            Integer preMonth  = MONTH_CODE_MAP.get(preMonthChar);
            Integer postMonth = MONTH_CODE_MAP.get(postMonthChar);
            if (preMonth == null || postMonth == null) {
                System.debug('Unknown month code!');
                return INVALID_RESULT;
            }

            if (postMonth > preMonth) return 1;
            if (postMonth < preMonth) return -1;

            // Same year & month → compare remaining sequence
            String preSeq  = preLast8.substring(2);
            String postSeq = postLast8.substring(2);

            String preDigits  = preSeq.replaceAll('[^0-9]', '');
            String postDigits = postSeq.replaceAll('[^0-9]', '');

            if (!String.isBlank(preDigits) && !String.isBlank(postDigits)) {
                Long preNum  = Long.valueOf(preDigits);
                Long postNum = Long.valueOf(postDigits);

                if (postNum > preNum) return 1;
                if (postNum < preNum) return -1;
                return 0;
            }

            // Fallback: lexicographic compare
            Integer lex = postSeq.compareTo(preSeq);
            if (lex > 0) return 1;
            if (lex < 0) return -1;
            return 0;

        } catch (Exception e) {
            System.debug('Error in compareVINFormat: ' + e.getMessage());
            return INVALID_RESULT;
        }
    }
}