/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 01-27-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
@isTest
public class GenericPermissionSetAssignerHandlerTest {
  @testSetup
  static void setupTestData() {
    // Fetched the standard profile
    Profile standardProfile = [
      SELECT Id
      FROM Profile
      WHERE Name = 'Standard User'
      LIMIT 1
    ];

    // Created source and target users
    List<User> users = new List<User>{
      new User(
        FirstName = 'Source',
        LastName = 'User',
        Email = 'sourceuser@example.com',
        Username = 'sourceuser@example.com.test',
        Alias = 'srcusr',
        ProfileId = standardProfile.Id,
        TimeZoneSidKey = 'America/New_York',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
      ),
      new User(
        FirstName = 'Target',
        LastName = 'User',
        Email = 'targetuser@example.com',
        Username = 'targetuser@example.com.test',
        Alias = 'tgtusr',
        ProfileId = standardProfile.Id,
        TimeZoneSidKey = 'America/New_York',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US'
      )
    };
    insert users;

    //Created New target User with standardProfile licence to cover negative scenarios.
    User newTargetUser = new User(
      FirstName = 'NewTarget',
      LastName = 'User',
      Email = 'targetuserelse@example.com',
      Username = 'targetuserelse@example.com.test',
      Alias = 'tgtusr',
      ProfileId = standardProfile.Id,
      TimeZoneSidKey = 'America/New_York',
      LocaleSidKey = 'en_US',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US'
    );
    insert newTargetUser;

    // Stored user IDs
    Id sourceUserId = users[0].Id;
    Id targetUserId = users[1].Id;
    Id newTargetUserId = newTargetUser.Id;

    // Create permission sets
    List<PermissionSet> permissionSets = new List<PermissionSet>();
    for (Integer i = 1; i <= 5; i++) {
      permissionSets.add(
        new PermissionSet(
          Name = 'CustomPermissionSet' + i,
          Label = 'Custom Permission Set ' + i
        )
      );
    }
    //creating permission set which name starts with X00 as standard permission set and added to permissionSets list which is assigned when user is created.
    permissionSets.add(
      new PermissionSet(
        Name = 'X00CustomPermissionSet',
        Label = 'X00 Custom Permission Set'
      )
    );
    insert permissionSets;

    // Assign all Six permission sets to the Source User.
    List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
    for (PermissionSet ps : permissionSets) {
      psaList.add(
        new PermissionSetAssignment(
          AssigneeId = sourceUserId,
          PermissionSetId = ps.Id
        )
      );
    }
    //Fetched standard permission set which needs to be assigned to Target User.
    PermissionSet psa = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'X00CustomPermissionSet'
      LIMIT 1
    ];

    // Assign Three specific permission sets to the target user.
    List<PermissionSetAssignment> psaListofTargetuser = new List<PermissionSetAssignment>();
    psaListofTargetuser.add(
      new PermissionSetAssignment(
        AssigneeId = targetUserId,
        PermissionSetId = permissionSets[0].Id
      )
    );
    psaListofTargetuser.add(
      new PermissionSetAssignment(
        AssigneeId = targetUserId,
        PermissionSetId = permissionSets[1].Id
      )
    );
    psaListofTargetuser.add(
      new PermissionSetAssignment(
        AssigneeId = targetUserId,
        PermissionSetId = psa.Id
      )
    );

    //Assign one standard Permission set to NewTarget user.
    psaListofTargetuser.add(
      new PermissionSetAssignment(
        AssigneeId = newTargetUserId,
        PermissionSetId = psa.Id
      )
    );

    // Insert all permission sets assignment.
    insert psaList;
    insert psaListofTargetuser;
  }
  /*Test method for checking is User Objet is accessiable for user.*/
  @isTest
  static void isAccForUserObjeTest() {
    Test.startTest();
    // Call the isAccForUserObje method
    Boolean isAccessible = GenericPermissionSetAssignerHandler.isAccForUserObje();

    // Verify the expected result
    if (Schema.sObjectType.User.isAccessible()) {
      System.assertEquals(
        true,
        isAccessible,
        'Expected User object to be accessible.'
      );
    } else {
      System.assertEquals(
        false,
        isAccessible,
        'Expected User object to be inaccessible.'
      );
    }
    Test.stopTest();
  }
  /*Test method is retriving the all Active and InActive Source Users.*/
  @isTest
  static void getSourceUsersTest() {
    Test.startTest();
    List<User> users = GenericPermissionSetAssignerHandler.getSourceUsers();
    Test.stopTest();

    System.assertNotEquals(
      0,
      users.size(),
      'Source users should be retrieved.'
    );
  }

  /*Test method for retriving the all Active Target Users.*/
  @isTest
  static void getTargetUsersTest() {
    User sourceUser = [SELECT Id FROM User WHERE FirstName = 'Source' LIMIT 1];
    User targetUser = [SELECT Id FROM User WHERE FirstName = 'Target' LIMIT 1];

    Test.startTest();
    List<User> targetUsers = GenericPermissionSetAssignerHandler.getTargetUsers(
      sourceUser.Id,
      targetUser.Id
    );
    Test.stopTest();

    System.assertNotEquals(
      1,
      targetUsers.size(),
      'Target users should be retrieved.'
    );
  }
  /*Test method for retriving all the assigned permission for source User except the Standard permission Set is Assigned*/
  @isTest
  static void getSourcePermissionSetTest() {
    User sourceUser = [SELECT Id FROM User WHERE FirstName = 'Source' LIMIT 1];

    Test.startTest();
    List<PermissionSetAssignment> psaList = GenericPermissionSetAssignerHandler.getSourcePermissionSet(
      sourceUser.Id
    );
    Test.stopTest();

    System.assertEquals(
      5,
      psaList.size(),
      'All 5 permission sets for the target user should be retrieved.'
    );
  }
  /*Test method for retriving all the assigned permission for Target User except the Standard permission Set is Assigned*/
  @isTest
  static void getTargetPermissionSetTest() {
    User targetUser = [SELECT Id FROM User WHERE FirstName = 'Target' LIMIT 1];

    Test.startTest();
    List<PermissionSetAssignment> psaList = GenericPermissionSetAssignerHandler.getTargetPermissionSet(
      targetUser.Id
    );
    Test.stopTest();

    System.assertEquals(
      2,
      psaList.size(),
      '2 permission sets for the source user should be retrieved.'
    );
  }
  /*Test method for assigning Custom Permission Set Functionallity to Target User.*/
  @isTest
  static void assignCustomPermissionSetsToTargetUserTest() {
    User sourceUser = [SELECT Id FROM User WHERE FirstName = 'Source' LIMIT 1];
    User targetUser = [SELECT Id FROM User WHERE FirstName = 'Target' LIMIT 1];
    PermissionSet psa = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'CustomPermissionSet1'
      LIMIT 1
    ];
    PermissionSet psaTwo = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'CustomPermissionSet2'
      LIMIT 1
    ];
    List<String> permissionSetIds = new List<String>();
    permissionSetIds.add(psa.Id);
    permissionSetIds.add(psaTwo.Id);

    Test.startTest();
    GenericPermissionSetAssignerHandler.assignCustomPermissionSetsToTargetUser(
      permissionSetIds,
      sourceUser.Id,
      targetUser.Id
    );
    Test.stopTest();

    List<PermissionSetAssignment> psaList = [
      SELECT Id
      FROM PermissionSetAssignment
      WHERE AssigneeId = :targetUser.Id
    ];
    System.assertNotEquals(
      0,
      psaList.size(),
      'Custom permission sets should be assigned to the target user.'
    );
  }
  /*Test method for assigning Custom Permission Set Functionallity to Target User with empty permission sets list*/
  @isTest
  static void assignCustomPermissionSetsToTargetUserNegativeTest() {
    User sourceUser = [SELECT Id FROM User WHERE FirstName = 'Source' LIMIT 1];
    User targetUser = [SELECT Id FROM User WHERE FirstName = 'Target' LIMIT 1];
    List<String> permissionSetIds = new List<String>();
    String exceptionMessage = '';
    Test.startTest();
    try {
      GenericPermissionSetAssignerHandler.assignCustomPermissionSetsToTargetUser(
        permissionSetIds,
        sourceUser.Id,
        targetUser.Id
      );
    } catch (AuraHandledException e) {
      exceptionMessage = e.getMessage();
    }
    Test.stopTest();
    System.assertNotEquals(
      '',
      exceptionMessage,
      'Expected exception to be thrown'
    );
  }
  /*Test method for assigning Upgrade Permission Sets positive Functionallity to Target User. */
  @isTest
  static void upgradePermissionSetOfTargetUserPositiveTest() {
    // Retrieve users and permission sets
    User sourceUser = [SELECT Id FROM User WHERE FirstName = 'Source' LIMIT 1];
    User targetUser = [SELECT Id FROM User WHERE FirstName = 'Target' LIMIT 1];
    PermissionSet newPermissionSet = [
      SELECT Id, Name
      FROM PermissionSet
      WHERE Name = 'CustomPermissionSet5'
      LIMIT 1
    ];
    PermissionSet x00PermissionSet = [
      SELECT Id, Name
      FROM PermissionSet
      WHERE Name = 'X00CustomPermissionSet'
      LIMIT 1
    ];
    Map<String, Boolean> upgradeMap = new Map<String, Boolean>();
    upgradeMap.put(newPermissionSet.Id, true);
    upgradeMap.put(x00PermissionSet.Id, true);
    String upgradeJson = JSON.serialize(upgradeMap);

    Boolean exceptionThrown = false;
    String exceptionMessage = '';
    Test.startTest();
    try {
      GenericPermissionSetAssignerHandler.upgradePermissionSetOfTargetUser(
        sourceUser.Id,
        targetUser.Id,
        upgradeJson
      );
    } catch (Exception e) {
      exceptionThrown = true;
      exceptionMessage = e.getMessage();
    }
    Test.stopTest();
    if (exceptionThrown) {
      System.assertEquals(
        'Script-thrown exception',
        exceptionMessage,
        'Expected error message'
      );
    } else {
      List<PermissionSetAssignment> targetAssignments = [
        SELECT PermissionSetId
        FROM PermissionSetAssignment
        WHERE AssigneeId = :targetUser.Id
      ];
      System.assertEquals(
        4,
        targetAssignments.size(),
        'The target user should have the expected upgraded permission sets assigned.'
      );
    }
  }
  /*Test method for assigning Upgrade Permission Sets negative Functionallity to Target User.*/
  @isTest
  static void upgradePermissionSetOfTargetUserNegativeTest() {
    User sourceUser = [SELECT Id FROM User WHERE FirstName = 'Source' LIMIT 1];
    User targetUser = [
      SELECT Id
      FROM User
      WHERE FirstName = 'NewTarget'
      LIMIT 1
    ];
    Map<String, Boolean> upgradeMap = new Map<String, Boolean>();
    String upgradeJson = JSON.serialize(upgradeMap);

    Test.startTest();
    GenericPermissionSetAssignerHandler.upgradePermissionSetOfTargetUser(
      sourceUser.Id,
      targetUser.Id,
      upgradeJson
    );
    Test.stopTest();
    // Fetch the assignments for the target user after execution
    List<PermissionSetAssignment> targetAssignmentsAfterUpgrade = [
      SELECT PermissionSet.Name
      FROM PermissionSetAssignment
      WHERE AssigneeId = :targetUser.Id
    ];
    System.assertEquals(
      7,
      targetAssignmentsAfterUpgrade.size(),
      'Six permission set of Source user should be upgrade to the target with one permission set of Target user.'
    );
  }
  /*Test method for assigning Clone Permission Sets positive Functionallity to Target User.*/
  @isTest
  static void clonePermissionSetOfTargetUserPositiveTest() {
    User sourceUser = [SELECT Id FROM User WHERE FirstName = 'Source' LIMIT 1];
    User targetUser = [SELECT Id FROM User WHERE FirstName = 'Target' LIMIT 1];
    PermissionSet psa = [
      SELECT Id
      FROM PermissionSet
      WHERE Name = 'CustomPermissionSet3'
      LIMIT 1
    ];

    Map<String, Boolean> cloneTarget = new Map<String, Boolean>();
    cloneTarget.put(psa.Id, true);

    String cloneTargetJson = JSON.serialize(cloneTarget);

    Test.startTest();
    GenericPermissionSetAssignerHandler.clonePermissionSetOfTargetUser(
      cloneTargetJson,
      sourceUser.Id,
      targetUser.Id
    );
    Test.stopTest();

    List<PermissionSetAssignment> psaList = [
      SELECT Id
      FROM PermissionSetAssignment
      WHERE AssigneeId = :targetUser.Id
    ];
    System.assertNotEquals(
      0,
      psaList.size(),
      'Permission sets should be cloned for the target user.'
    );
  }
  /*Test method for assigning Clone Permission Sets negative Functionallity to Target User.*/
  @isTest
  static void clonePermissionSetOfTargetUserNegativeTest() {
    User sourceUser = [SELECT Id FROM User WHERE FirstName = 'Source' LIMIT 1];
    User targetUser = [
      SELECT Id
      FROM User
      WHERE FirstName = 'NewTarget'
      LIMIT 1
    ];
    Map<String, Boolean> cloneTarget = new Map<String, Boolean>();
    String cloneJson = JSON.serialize(cloneTarget);

    Boolean exceptionThrown = false;
    String exceptionMessage = '';
    Test.startTest();
    try {
      GenericPermissionSetAssignerHandler.clonePermissionSetOfTargetUser(
        cloneJson,
        sourceUser.Id,
        targetUser.Id
      );
    } catch (Exception e) {
      exceptionThrown = true;
      exceptionMessage = e.getMessage();
    }
    Test.stopTest();
    if (exceptionThrown) {
      System.assertEquals(
        'Script-thrown exception',
        exceptionMessage,
        'Expected error message'
      );
    } else {
      List<PermissionSetAssignment> targetAssignmentsAfterUpgrade = [
        SELECT PermissionSet.Name
        FROM PermissionSetAssignment
        WHERE AssigneeId = :targetUser.Id
      ];

      System.assertEquals(
        7,
        targetAssignmentsAfterUpgrade.size(),
        'Six permission sets of Source user should be cloned to the target with one Standard permission set of Target user.'
      );
    }
  }
}