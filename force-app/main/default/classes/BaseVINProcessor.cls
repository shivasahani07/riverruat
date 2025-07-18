/*
* @description         : dd/MM/yyyy
* @author              : Sagar Kumar
* @created on          : dd/MM/yyyy
* @last modified on    : 
* @last modified date  : 
* -----------------------------------------------------------------------------------------------------
*/

public virtual class BaseVINProcessor {
    protected List<String> vinList;
    protected Id fieldFixId;
    
    public BaseVINProcessor(String vinCSV, Id fieldFixId) {
        this.fieldFixId = fieldFixId;
        this.vinList = parseVINs(vinCSV);
    }
    
    public virtual String execute() {
        return 'Base processor';
    }
    
    private List<String> parseVINs(String csv) {
        List<String> list1 = new List<String>();
        for (String v : csv.split('[\\n,]+')) {
            if (!String.isBlank(v.trim())) {
                list1.add(v.trim());
            }
        }
        return list1;
    }
    
    public static Boolean isNumeric(String str) {
        if (String.isBlank(str)) return false;
        try {
            Integer.valueOf(str);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
    
    
}