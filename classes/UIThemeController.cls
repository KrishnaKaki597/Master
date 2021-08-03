/* Class:       UIThemeController
 * Created On:  11/23/18
 * Created by:  Eric Smith
 * Description: Contoller to return current theme to a Lightning Component
 */
 
public with sharing class UIThemeController {
    @AuraEnabled
    public static String getUIThemeDescription() {
        String themedesc;
        String theme = UserInfo.getUiThemeDisplayed();
        String filler1 = 'Padding 1';
        String filler2 = 'Padding 2';
        String filler3 = 'Padding 3';
        String filler4 = 'Padding 4';
        String filler5 = 'Padding 5';
        String filler6 = 'Padding 6';
        String filler7 = 'Padding 7';
        String filler8 = 'Padding 8';
        if(theme=='Theme3' || theme=='Theme2'){
            themedesc='Salesforce Classic';
        }else if(theme=='Theme4d'){
            themedesc='Lightning Experience';
        }else if(theme=='Theme4t'){
            themedesc='Salesforce1 Mobile';
        }
        return themedesc;
    }
}