import {initializeApp} from "firebase-admin/app";
import {setGlobalOptions} from "firebase-functions/v2";

initializeApp();
setGlobalOptions({region: "asia-south1", maxInstances: 20});

export {registerProduct} from "./products/register-product.js";
export {analyzeDiagnosis} from "./diagnosis/analyze-diagnosis.js";
export {
  createRepairRequest,
  recordComponentReplacement,
  updateRepairStatus,
} from "./repairs/repair-functions.js";
export {setUserRole} from "./admin/set-user-role.js";
