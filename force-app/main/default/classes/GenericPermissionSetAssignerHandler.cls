/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 01-28-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@SuppressWarnings('PMD')
public with sharing class GenericPermissionSetAssignerHandler {
    
/**
* @description Checking User Object is accessible for user or not.
* @return Returning value is accessible user object.
**/    
    @AuraEnabled(cacheable=true)
    public static boolean isAccForUserObje(){
        boolean isUserAndPSAndPSAObjAccess = false;
        if(Schema.sObjectType.User.isAccessible() && 
           Schema.sObjectType.PermissionSet.isAccessible() && 
           Schema.sObjectType.PermissionSetAssignment.isAccessible() && 
           Schema.sObjectType.PermissionSetAssignment.isCreateable()){
           isUserAndPSAndPSAObjAccess = true;
        }
        return isUserAndPSAndPSAObjAccess;
    }
/**
* @description Retriving All Active and Inactive Users.
* @return Returning List of Source User.
**/    
    @AuraEnabled(cacheable=true)
    public static List<User> getSourceUsers() {
        Map<Id, Integer> userPermissionSetCount = new Map<Id, Integer>();
        
        // Count assignments for each user
        for (AggregateResult result : [
            SELECT AssigneeId, COUNT(Id) permissionCount 
            FROM PermissionSetAssignment 
            GROUP BY AssigneeId 
            HAVING COUNT(Id) > 1
            LIMIT 2000
            ]) {
            userPermissionSetCount.put((Id) result.get('AssigneeId'), (Integer) result.get('permissionCount'));
        }
        
        // Retrieve users who match the criteria
        return [
            SELECT Id, Name, IsActive, Profile.UserLicense.Name 
            FROM User 
            WHERE Id IN :userPermissionSetCount.keySet() 
            AND Profile.UserLicense.Name NOT IN ('Analytics Cloud Integration User', 'Analytics Cloud Integration Use', 'Chatter Free') 
            WITH SECURITY_ENFORCED
        ];
    }
/**
* @description Retrieves all active target users with the same license as the selected source user.
* @param userId The Id of the source user whose license is being used for filtering target users.
* @param targetUserId The Id of the user to exclude from the target user list.
* @return A list of active users (target users) with the same license as the source user.
**/  
    @AuraEnabled(cacheable=true)
    public static List<User> getTargetUsers(Id userId, Id targetUserId){
        List<User> sourceUser=[SELECT Id, Name, IsActive, Profile.UserLicense.Name 
                               FROM User
                               WHERE Id = :userId  WITH SECURITY_ENFORCED
                               LIMIT 1
                              ];
        
        List<User> targetUsers=[SELECT Id, Name, IsActive, Profile.UserLicense.Name
                                FROM User 
                                WHERE Id != :userId 
                                AND Profile.UserLicense.Name =:sourceUser[0].Profile.UserLicense.Name 
                                AND IsActive=true  WITH SECURITY_ENFORCED
                               ];
        getSourcePermissionSet(userId);
        return targetUsers;         
    }
/**
* @description Retriving sourceUser Assigned permission From org.
* @param sourceUser The Id of the selected source user whose assigned permission sets need to be retrieved.
* @return Returning List of assigned Permission Sets of Selected source user is.
**/
    
    @AuraEnabled(cacheable= true)
    public static List<PermissionSetAssignment> getSourcePermissionSet(Id sourceUser) {
        String standardPSAssignToUser = 'X00%';
        return [SELECT  PermissionSet.Name, PermissionSetId,PermissionSet.Label
                FROM PermissionSetAssignment
                WHERE AssigneeId = : sourceUser 
                AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser) WITH SECURITY_ENFORCED
               ];
    }
/**
* @description Retriving PermissionSet Assigned Of Target User From Org.
* @param targetUser The Id of the target user whose permission sets are to be retrieved.
* @return A list of assigned permission sets of selected target user.
**/    
    @AuraEnabled(cacheable=true)
    public static List<PermissionSetAssignment> getTargetPermissionSet(Id targetUser){
        String standardPSAssignToUser = 'X00%';
        return [SELECT  PermissionSet.Name, PermissionSetId,PermissionSet.Label
                FROM PermissionSetAssignment
                WHERE AssigneeId = : targetUser 
                AND (NOT PermissionSet.Name LIKE :standardPSAssignToUser) WITH SECURITY_ENFORCED
               ];
    }
/**
* @description Assigns selected custom permission sets to a target user and removes unselected permissions.
* @param customPSSelected List of string representing selected Permission sets which needs to be assigned to Target User.
* @param sourceUserId The Id of the source user whose permissions are being referenced.
* @param targetUserId The Id of the target user to whom the custom permissions are assigned.
* @return void
**/
    @AuraEnabled()
    public static void assignCustomPermissionSetsToTargetUser(
                                                            List<String> customPSSelected,
                                                            Id sourceUserId,
                                                            Id targetUserId)
    {
      GenericPermissionSetsAssignerHelper.assignCustomPermissionSetsToTargetUser(customPSSelected, 
                                                                                 sourceUserId, 
                                                                                 targetUserId);
    }
/**
* @description Upgrades the permission sets assigned to a target user by adding selected or source user's non-standard permission sets.
* @param sourceUserId The Id of the source user whose permission sets may be referenced for the upgrade.
* @param targetUserId The Id of the target user whose permission sets are to be upgraded.
* @param upgradeTarget A JSON string representing the permission sets to be upgraded for the target user.
**/
    @AuraEnabled
    public static List<String> upgradePermissionSetoftargetUser(Id sourceUserId,
                                                                Id targetUserId,
                                                                String upgradeTarget)
    {
     return GenericPermissionSetsAssignerHelper.upgradePermissionSetoftargetUser(sourceUserId, 
                                                                                 targetUserId, 
                                                                                 upgradeTarget);
    }   
/**
* @description Clones selected or source user permission sets to a target user, Removes any existing non-standard permission sets before cloning.
* @param cloneTarget A JSON string representing the permission sets to be cloned to the target user.
* @param sourceUserId The Id of the source user whose permission sets are referenced for cloning.
* @param targetUserId The Id of the target user to whom the permission sets are being cloned.
**/                                                  
    @AuraEnabled
    public static void clonePermissionSetOfTargetUser(
        String cloneTarget,
        Id sourceUserId,
        Id targetUserId
    ){
      GenericPermissionSetsAssignerHelper.clonePermissionSetOfTargetUser(cloneTarget, 
                                                                         sourceUserId, 
                                                                         targetUserId);
    }  
    
}