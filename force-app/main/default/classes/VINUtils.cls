public class VINUtils {
    // Year codes mapping
    private static Map<String, Integer> yearCodeMap = new Map<String, Integer>{
        'R' => 2024, 'S' => 2025, 'T' => 2026, 'V' => 2027, 'W' => 2028,
        'X' => 2029, 'Y' => 2030, 'A' => 2031, 'B' => 2032, 'C' => 2033,
        'D' => 2034, 'E' => 2035, 'F' => 2036, 'G' => 2037, 'H' => 2038,
        'J' => 2039, 'K' => 2040, 'L' => 2041, 'M' => 2042, 'N' => 2043,
        '1' => 2044, '2' => 2045, '3' => 2046, '4' => 2047, '5' => 2048,
        '6' => 2049, '7' => 2050, '8' => 2051, '9' => 2052, 'P' => 2053
    };

    // Month codes mapping
    private static Map<String, Integer> monthCodeMap = new Map<String, Integer>{
        'A' => 1, 'B' => 2, 'C' => 3, 'D' => 4, 'E' => 5, 'F' => 6,
        'G' => 7, 'H' => 8, 'J' => 9, 'K' => 10, 'L' => 11, 'M' => 12
    };

    // Wrapper for result
    public class VINComparisonResult {
        @AuraEnabled public Boolean isAfter;
        @AuraEnabled public String reason;
    }

    /**
     * Compare two VINs and return result + reason
     */
    public static VINComparisonResult compareVINs(String n1, String n2) {
        VINComparisonResult result = new VINComparisonResult();
        result.isAfter = false;
        result.reason = 'UNKNOWN';

        if (String.isBlank(n1) || String.isBlank(n2) || n1.length() != 17 || n2.length() != 17) {
            result.reason = 'INVALID_VIN';
            return result;
        }

        try {
            // Step 1: Compare Series
            String series1 = n1.substring(0, 9);
            String series2 = n2.substring(0, 9);
            if (series1 != series2) {
                result.reason = 'DIFFERENT_SERIES';
                return result;
            }

            // Step 2: Extract Year & Month
            Integer year1 = yearCodeMap.get(n1.substring(10, 11));
            Integer year2 = yearCodeMap.get(n2.substring(10, 11));
            Integer month1 = monthCodeMap.get(n1.substring(9, 10));
            Integer month2 = monthCodeMap.get(n2.substring(9, 10));

            if (year1 == null || year2 == null || month1 == null || month2 == null) {
                result.reason = 'INVALID_YEAR_MONTH_CODE';
                return result;
            }

            // Step 3: Compare Year
            if (year2 > year1) {
                result.isAfter = true;
                result.reason = 'AFTER_BY_YEAR';
                return result;
            }
            if (year2 < year1) {
                result.isAfter = false;
                result.reason = 'BEFORE_BY_YEAR';
                return result;
            }

            // Step 4: Compare Month
            if (month2 > month1) {
                result.isAfter = true;
                result.reason = 'AFTER_BY_MONTH';
                return result;
            }
            if (month2 < month1) {
                result.isAfter = false;
                result.reason = 'BEFORE_BY_MONTH';
                return result;
            }

            // Step 5: Compare Serial
            Integer serial1 = Integer.valueOf(n1.substring(11));
            Integer serial2 = Integer.valueOf(n2.substring(11));

            if (serial2 > serial1) {
                result.isAfter = true;
                result.reason = 'AFTER_BY_SERIAL';
            } else if (serial2 < serial1) {
                result.isAfter = false;
                result.reason = 'BEFORE_BY_SERIAL';
            } else {
                result.isAfter = false;
                result.reason = 'SAME_VIN';
            }
            return result;

        } catch (Exception e) {
            result.reason = 'ERROR: ' + e.getMessage();
            return result;
        }
    }
}