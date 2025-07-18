public class LeadPhoneValidator {
    public static void checkForDuplicatePhones(List<Lead> newLeads) {
        for (Lead l : newLeads) {
            if (String.isBlank(l.Phone)) continue;

            String normalized = PhoneNumberFormatter.extractPhoneNumber(l.Phone);

            if (String.isBlank(normalized)) {
                l.addError('Invalid phone number format');
                continue;
            }
            
            if (normalized.startsWith('INVALID') || normalized.startsWith('INSUFFICIENT')) {
                l.addError('Invalid phone number: ' + normalized);
                continue;
            }
            
            l.Phone = normalized;
        }
    }
}