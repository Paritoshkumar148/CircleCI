import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import assignCustomPermissionSetsToTargetUser from "@salesforce/apex/GenericPermissionSetAssignerHandler.assignCustomPermissionSetsToTargetUser";
import clonePermissionSetOfTargetUser from "@salesforce/apex/GenericPermissionSetAssignerHandler.clonePermissionSetOfTargetUser";
import getSourcePermissionSet from "@salesforce/apex/GenericPermissionSetAssignerHandler.getSourcePermissionSet";
import getSourceUsers from "@salesforce/apex/GenericPermissionSetAssignerHandler.getSourceUsers";
import getTargetPermissionSet from "@salesforce/apex/GenericPermissionSetAssignerHandler.getTargetPermissionSet";
import getTargetUsers from "@salesforce/apex/GenericPermissionSetAssignerHandler.getTargetUsers";
import isAccForUserObje from "@salesforce/apex/GenericPermissionSetAssignerHandler.isAccForUserObje";
import upgradePermissionSetoftargetUser from "@salesforce/apex/GenericPermissionSetAssignerHandler.upgradePermissionSetoftargetUser";
export default class GenericPermissionSetAssignerComponent extends LightningElement {

  @track optionsForSource = [];
  @track optionsForTarget = [];
  @track sourceUserAssignPS = [];
  @track targetUserAssignPS = [];
  @track dualListboxOptions = [];
  @track selectedDualPermissionSet = [];
  @track cancelTriggered = false;
  @track upgradePermission = false;
  @track clonePermission = false;
  @track customPermission = false;
  @track sourceUserId;
  @track targetUserId;
  @track showContent = false;
  storeselectedDualPermissionSet = [];
  targetUpgradePermissions = new Map();
  targetClonePermissions = new Map();
  isUserObjAccessible = false;
  isLoaded = false;
  result;
  //Functionality of checkUserObjectAccessibility Method to check is user is having accessibility of Manage Users.
  checkUserObjectAccessibility() {
    isAccForUserObje()
      .then((data) => {
        this.isUserObjAccessible = data;
        if (this.isUserObjAccessible) {
          this.loadSourceUsers();
        } else {
          this.showToast( "Access Denied: ", `You lack the necessary permissions to assign Permission Sets. Please contact your system administrator for assistance.`, "Error");
        }
      })
      .catch((error) => {
        this.showToast("Insufficient Access: ",`${error.body.message}`,"Error" );
      })
      .finally(() => {
        this.isLoaded = true;
      });
  }

  //Retriving all active inactive users from org.
  loadSourceUsers() {
    getSourceUsers()
      .then((data) => {
        const allUsers = [];
        data.forEach((user) => {
          allUsers.push({ label: user.Name, value: user.Id });
        });
        this.optionsForSource = allUsers;
      })
      .catch((error) => {
        this.showToast("No user exists in this org: ",` ${error.body.message}`, "Error");
      });
  }
  handleSourceChange(event) {
    this.sourceUserId = event.detail.value;
    this.targetUserId = undefined;
    this.optionsForTarget = [];
    this.targetUserAssignPS = [];
    this.sourceUserAssignPS = [];
    this.targetUpgradePermissions = new Map();
    this.targetClonePermissions = new Map();
    this.dualListboxOptions = [];
    this.selectedDualPermissionSet = [];
    this.showContent = false;
  }
  //Retriving Assigned Permission Sets of selected Source User.
  @wire(getSourcePermissionSet, { sourceUser: "$sourceUserId" })
  SourceUserAssignedPS({ error, data }) {
    if (data) {
      const allSourcePermissionSet = [];
      data.forEach((PermissionSetAssignment) => {
        allSourcePermissionSet.push({
          label: PermissionSetAssignment.PermissionSet.Label,
          value: PermissionSetAssignment.PermissionSetId
        });
      });
      this.dualListboxOptions = allSourcePermissionSet;
      this.sourceUserAssignPS = allSourcePermissionSet;
    } else if (error) {
      this.showToast("Error retriving the Source User Permission Sets: ", ` ${error.body.message}`,"Error");
    }
  }

  //Retriving all active Taregt Users which is having same licence as Selected Source User.
  @wire(getTargetUsers, { userId: "$sourceUserId" })
  Targetusers({ error, data }) {
    if (data) {
      const allUsers = [];
      data.forEach((user) => {
        allUsers.push({ label: user.Name, value: user.Id });
      });
      this.optionsForTarget = allUsers;
    } else if (error) {
      this.showToast("Error retriving Target User: ", `${error.body.message}`, "Error");
    }
  }
  handleTargetChange(event) {
    this.targetUserId = event.detail.value;
    this.showContent = true;
  }
  //Retriving all assigned Permission Sets for selected Target User.
  @wire(getTargetPermissionSet, { targetUser: "$targetUserId" })
  TargetUserAssignedPS({ error, data }) {
    if (data) {
      const allTargetPermissionSet = data.map((PermissionSetAssignment) => ({
        label: PermissionSetAssignment.PermissionSet.Label,
        value: PermissionSetAssignment.PermissionSetId
      }));
      this.selectedDualPermissionSet = allTargetPermissionSet.map(
        (permissionSet) => permissionSet.value
      );
      this.dualListboxOptions = [
        ...this.dualListboxOptions,
        ...allTargetPermissionSet
      ].filter(
        (item, index, self) =>
          index === self.findIndex((option) => option.value === item.value)
      );
      this.targetUserAssignPS = allTargetPermissionSet;
      this.storeselectedDualPermissionSet = this.selectedDualPermissionSet;
    } else if (error) {
      this.showToast("Error retrieving the Target User Permission Sets: ",`${error.body.message}`,"Error");
    } 
  }

  //Handling active section is Custom/Upgrade/Clone section is open
  handleSectionToggle(event) {
    const ActiveSections = event.detail.openSections;
    if (ActiveSections.includes("CustomPermission")) {
      this.setCustomPermissionState();
    } else if (ActiveSections.includes("UpgradePermission")) {
      this.setUpgradePermissionState();
    } else if (ActiveSections.includes("ClonePermission")) {
      this.setClonePermissionState();
    }
  }
  setCustomPermissionState() {
    this.customPermission = true;
    this.selectedDualPermissionSet = this.storeselectedDualPermissionSet;
    this.resetPermissions(["upgrade", "clone"]);
  }
  setUpgradePermissionState() {
    this.upgradePermission = true;
    this.resetPermissions(["custom", "clone"]);
  }
  setClonePermissionState() {
    this.clonePermission = true;
    this.resetPermissions(["custom", "upgrade"]);
  }
  resetPermissions(statesToReset) {
    if (statesToReset.includes("custom")) {
      this.customPermission = false;
      this.selectedDualPermissionSet = [];
    }
    if (statesToReset.includes("upgrade")) {
      this.upgradePermission = false;
      this.targetUpgradePermissions = new Map();
    }
    if (statesToReset.includes("clone")) {
      this.clonePermission = false;
      this.targetClonePermissions = new Map();
    }
  }
  //Handling Permission set which is selected for assigning to Target User.
  handleChangePSForCustomFunctionality(event) {
    this.selectedDualPermissionSet = event.detail.value;
    this.storeselectedDualPermissionSet = this.selectedDualPermissionSet;
  }
  handlePermissionSetChangeUpgradeSource(event) {
    this.targetUpgradePermissions[event.target.dataset.id] = event.target.checked;
  }
  handlePermissionSetChangeCloneSource(event) {
    this.targetClonePermissions[event.target.dataset.id] = event.target.checked;
  }

  handleSave() {
    if (this.isValidInputs()) {
      if (this.customPermission) {
        this.assignCustomPermissions();
      } else if (this.upgradePermission) {
        this.upgradePermissions();
      } else if (this.clonePermission) {
        this.clonePermissions();
      }
    } else {
      this.showValidationErrors();
    }
  }
  // Check if all the selected inputs are valid to assign Permission Sets to Target User.
  isValidInputs() {
    const EMPTY_ARRAY_LENGTH = 0;
    return (this.sourceUserId && this.targetUserId && ((this.upgradePermission && Object.keys(this.targetUpgradePermissions).length) ||(this.clonePermission && Object.keys(this.targetClonePermissions).length) ||
        (this.customPermission && this.selectedDualPermissionSet.length > EMPTY_ARRAY_LENGTH)));
  }
  // Customize selected Permission sets for Target User.
  assignCustomPermissions() {
    assignCustomPermissionSetsToTargetUser({customPSSelected: this.selectedDualPermissionSet, sourceUserId: this.sourceUserId,targetUserId: this.targetUserId})
      .then((result) => {
        this.result = result;
        this.showToast("Success!","Permissions have been successfully assigned to Target User.","success");
        window.location.reload();})
      .catch((error) => {
        this.handlePermissionAssignmentError(error);
      });
  }
  // Upgrade selected Permission Sets for Target User.
  upgradePermissions() {
    upgradePermissionSetoftargetUser({sourceUserId: this.sourceUserId, targetUserId: this.targetUserId, upgradeTarget: JSON.stringify(this.targetUpgradePermissions)})
      .then((result) => {
        const EMPTY_ARRAY_LENGTH = 0;
        if (result.length > EMPTY_ARRAY_LENGTH) {
          result.forEach((message) => {
            if (message.startsWith("Something went wrong")) {
              this.showToast("Error", message, "error");
            } else if (message.startsWith("Upgrade Action Failed")) {
              this.showToast("Warning", message, "Warning");
              window.location.reload();
            } else if (message.startsWith("No Changes")) {
              this.showToast("Warning", message, "warning");
            }
          });
        } else {
          this.showToast( "Success!", "Permissions have been successfully assigned to Target User.","success");
          window.location.reload();}
        })
      .catch((error) => {
        this.handlePermissionAssignmentError(error);
      });
  }
  // Clone selected permission Sets for Target User.
  clonePermissions() {
    clonePermissionSetOfTargetUser({cloneTarget: JSON.stringify(this.targetClonePermissions), sourceUserId: this.sourceUserId, targetUserId: this.targetUserId})
      .then((result) => {
        this.result = result;
        this.showToast( "Success!", "Permissions have been successfully assigned to Target User.", "success");
        window.location.reload(); })
      .catch((error) => {
        this.handlePermissionAssignmentError(error);
      });
  }
  // Show validation error messages
  showValidationErrors() {
    if (this.sourceUserId && !this.targetUserId) {
      this.showToast("Target User is not selected: ", "Please select a Target User to proceed.", "error");
    } else if (!this.sourceUserId && this.targetUserId) {
      this.showToast("Source User Is not selected: ", "Please select a Source User to proceed", "error");
    } else if (!this.sourceUserId && !this.targetUserId) {
      this.showToast("Source User and Target User has not been selected: ", "Please select both Source and Target Users to continue.", "error");
    } else if (!this.upgradePermission && !this.clonePermission && !this.customPermission) {
      this.showToast("Permission type is not selected: ", " Please choose Custom, Upgrade, or Clone to proceed.", "error");
    } else {
      this.showToast("No Permission Sets have been selected: ", "Please select Permission Sets to assign to the Target User.","error");
    }
  }
  handlePermissionAssignmentError(error) {
    this.showToast("Failed to Assign Permission Set: ",`${error.body.message}`,"error");
  }
 
  showToast(title, message, variant) {
    if (!import.meta.env.SSR) {
      this.dispatchEvent(new ShowToastEvent({ message, title, variant }));
    }
  }
  handleCancel() {
    this.cancelTriggered = true;
    window.location.reload();
  }
  loadData() {
    this.checkUserObjectAccessibility();
  }
  connectedCallback() {
    this.loadData();
  }
}