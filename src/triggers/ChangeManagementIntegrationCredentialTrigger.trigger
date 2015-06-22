trigger ChangeManagementIntegrationCredentialTrigger on Change_Management_Integration_Credential__c (before insert, before update) {
    
    /**
     * Force Password field encoding Base64 to avoid security issues
     */
  	for(Change_Management_Integration_Credential__c c:Trigger.new){
        if(c.Password__c!=null){
            try{
                //try to decode in order to avoid double encoding
                String decoded = EncodingUtil.base64Decode(c.Password__c).toString();
            }catch(Exception e){
                // it was not encoded, so it needs to be encoded
                c.Password__c = EncodingUtil.base64Encode(blob.valueOf(c.Password__c));
            }
        }    
    }
}