public class DiscrepancyLineItemHelper {
    
    public DiscrepancyLineItemHelper(ApexPages.StandardSetController cntlr){
        
    }
    
    public PageReference redirectToLC() {
        String currentUrl = ApexPages.currentPage().getUrl();
        System.debug('Current List View URL: ' + currentUrl);
        String filterName = ApexPages.currentPage().getParameters().get('filterName');        
        System.debug('Current List View Filter Name: ' + filterName);
        String returnUrl = '/lightning/cmp/c__DiscrepancyLineListViewButtonAura?c__filterName=' + EncodingUtil.urlEncode(filterName, 'UTF-8');
        PageReference pgReturnPage = new PageReference(returnUrl);
        pgReturnPage.setRedirect(true);
        return pgReturnPage;
    } 
    
}