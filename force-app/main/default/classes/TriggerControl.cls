public class TriggerControl {
    private static Map<String, Boolean> flags = new Map<String, Boolean>();

    public static Boolean runOnce(String key) {
        if (flags.containsKey(key)) {
            return false;
        }
        flags.put(key, true);
        return true;
    }
}