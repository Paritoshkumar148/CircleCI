/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 01-28-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

@SuppressWarnings('PMD')
public with sharing class GenericPermissionSetsAssignerHelper {
/**
* @description Assigns selected custom permission sets to a target user and removes unselected permissions.
* @param customPSSelected List of string representing selected Permission sets which needs to be assigned to Target User.
* @param sourceUserId The Id of the source user whose permissions are being referenced.
* @param targetUserId The Id of the target user to whom the custom permissions are assigned.
* @return void
**/    
    public static void assignCustomPermissionSetsToTargetUser(
        List<String> customPSSelected,
        Id sourceUserId,
        Id targetUserId
    ) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get('PermissionSetAssignment');
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        List<PermissionSetAssignment> psaListToBeInserted = new List<PermissionSetAssignment>();
        List<PermissionSet> assignedPSSource = [SELECT Id
                                                FROM PermissionSet 
                                                WHERE Id IN :customPSSelected WITH SECURITY_ENFORCED];
        String standardPSAssignToUser = 'X00%';                                       
        List<PermissionSetAssignment> permissionSetAssignments = [SELECT Id
                                                                  FROM PermissionSetAssignment
                                                                  WHERE AssigneeId = :targetUserId
                                                                  AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser) WITH SECURITY_ENFORCED
                                                                 ];
        if (permissionSetAssignments.size() > 0) {
                try {
                     if(objDescribe.isDeletable()){
                        delete permissionSetAssignments;
                     }
                } catch (Exception e) { 
                    throw new AuraHandledException('Something went wrong :' + e.getMessage());
                }   
            
        }
        
        for (Id psId : customPSSelected) {
            psaListToBeInserted.add(new PermissionSetAssignment(
                AssigneeId = targetUserId,
                PermissionSetId = psId
            ));
        }
        if (psaListToBeInserted.size() > 0) {
            try {
                    insert psaListToBeInserted;
                } catch (Exception e) {
                    throw new AuraHandledException('Something went wrong: ' + e.getMessage());
                }     
        } else {    
            throw new AuraHandledException('Custom Action Failed: "Selected permission sets have not assigned to Target Use"');
        }
    }
    
    /**
* @description Upgrades the permission sets assigned to a target user by adding selected or source user's non-standard permission sets.
* @param sourceUserId The Id of the source user whose permission sets may be referenced for the upgrade.
* @param targetUserId The Id of the target user whose permission sets are to be upgraded.
* @param upgradeTarget A JSON string representing the permission sets to be upgraded for the target user.
**/
    public static List<String> upgradePermissionSetoftargetUser(
        Id sourceUserId,
        Id targetUserId,
        String upgradeTarget
    ) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get('PermissionSetAssignment');
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Boolean> upgradeTargetPermission = (Map<String, Boolean>) JSON.deserialize(upgradeTarget, Map<String, Boolean>.class);
        List<PermissionSetAssignment> psaNeedToBeUpgratedForTargetUser = new List<PermissionSetAssignment>();
        List<Id> targetUserpermissionSetIds = new List<Id>();
        List<String> resultMessages = new List<String>();
        String standardPSAssignToUser = 'X00%';
        
        List<PermissionSetAssignment> assignedTargetPermissions = [SELECT PermissionSetId 
                                                                   FROM PermissionSetAssignment
                                                                   WHERE AssigneeId = :targetUserId 
                                                                   AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser) WITH SECURITY_ENFORCED
                                                                  ]; 
        for (PermissionSetAssignment psa : assignedTargetPermissions) {
            targetUserpermissionSetIds.add(psa.PermissionSetId);
        }
        if (upgradeTargetPermission.size() > 0) {
            for (Id psId : upgradeTargetPermission.keySet()) {
                if (!targetUserpermissionSetIds.contains(psId) && upgradeTargetPermission.get(psId)) {
                    psaNeedToBeUpgratedForTargetUser.add(new PermissionSetAssignment(
                        AssigneeId = targetUserId,
                        PermissionSetId = psId
                    ));
                }
            }
        } else {
            List<PermissionSetAssignment> psaIds = [SELECT PermissionSetId
                                                    FROM PermissionSetAssignment
                                                    WHERE AssigneeId = :sourceUserId 
                                                    AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser) WITH SECURITY_ENFORCED];
            for (PermissionSetAssignment psId : psaIds) {
                if (!targetUserpermissionSetIds.contains(psId.PermissionSetId)) {
                    psaNeedToBeUpgratedForTargetUser.add(new PermissionSetAssignment(
                        AssigneeId = targetUserId,
                        PermissionSetId = psId.PermissionSetId
                    ));
                }
            }                        
        }
        
        if (psaNeedToBeUpgratedForTargetUser.size() > 0) {
            if( objDescribe.isCreateable()){
                 try {
                    insert psaNeedToBeUpgratedForTargetUser;
                } catch (Exception e) {
                    resultMessages.add('Something went wrong: ' + e.getMessage());
                }   
            }else{
                resultMessages.add('Upgrade Action Failed: "You lack permissions to Manage Users. Please contact your system administrator."');
            }  
        } else {
            resultMessages.add('No Changes: Selected permission set is already assigned to Target User.');
        }
        
        return resultMessages;
    }
    /**
* @description Clones selected or source user permission sets to a target user, Removes any existing non-standard permission sets before cloning.
* @param cloneTarget A JSON string representing the permission sets to be cloned to the target user.
* @param sourceUserId The Id of the source user whose permission sets are referenced for cloning.
* @param targetUserId The Id of the target user to whom the permission sets are being cloned.
**/ 
    public static void clonePermissionSetOfTargetUser(
        String cloneTarget,
        Id sourceUserId,
        Id targetUserId
    ) {
        Schema.SObjectType objType = Schema.getGlobalDescribe().get('PermissionSetAssignment');
        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
        Map<String, Boolean> cloneTargetPermission = (Map<String, Boolean>) JSON.deserialize(cloneTarget, Map<String, Boolean>.class);
        String standardPSAssignToUser = 'X00%';
        List<PermissionSetAssignment> psaNeedToBeClonedForTargetUser = new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> targetUserAssignedPermissions = [SELECT PermissionSetId 
                                                                       FROM PermissionSetAssignment
                                                                       WHERE AssigneeId = :targetUserId 
                                                                       AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser) WITH SECURITY_ENFORCED
                                                                      ];
        if (targetUserAssignedPermissions.size() > 0) {
            try {
                    if(objDescribe.isDeletable()){
                       delete targetUserAssignedPermissions;
                    }
                } catch (Exception e) { 
                    throw new AuraHandledException('Something went wrong: ' + e.getMessage());
                } 
        }
        
        if (cloneTargetPermission.size() > 0) {
            for (Id psId : cloneTargetPermission.keySet()) {
                if (cloneTargetPermission.get(psId)) {
                    psaNeedToBeClonedForTargetUser.add(new PermissionSetAssignment(
                        AssigneeId = targetUserId,
                        PermissionSetId = psId
                    ));
                }
            }
        } else {                 
            List<PermissionSetAssignment> PSAIds = [SELECT PermissionSetId
                                                    FROM PermissionSetAssignment
                                                    WHERE AssigneeId = :sourceUserId
                                                    AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser) WITH SECURITY_ENFORCED];
            for (PermissionSetAssignment psId : PSAIds) {
                psaNeedToBeClonedForTargetUser.add(new PermissionSetAssignment(
                    AssigneeId = targetUserId,
                    PermissionSetId = psId.PermissionSetId
                ));
            }
        }
        
        if (psaNeedToBeClonedForTargetUser.size() > 0 && objDescribe.isCreateable()) {
            try {
                insert psaNeedToBeClonedForTargetUser;
            } catch (Exception e) {
                throw new AuraHandledException('Something went wrong :' + e.getMessage());
            }
        } else {
            throw new AuraHandledException('Clone Action Failed: "You lack permissions to Manage Users. Please contact your system administrator."');
        }
    }
}