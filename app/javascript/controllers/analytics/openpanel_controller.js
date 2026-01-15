import { Controller } from "@hotwired/stimulus";
import { OpenPanel } from "@openpanel/web";
import {
  getMetaJSON,
  getMetaContent,
  getRailsEnvironment,
} from "../../utils/meta";

export default class extends Controller {
  connect() {
    if (window.op) return;

    const railsEnv = getRailsEnvironment();
    const endpoint = getMetaContent("openpanel-endpoint");
    const token = getMetaContent("openpanel-token");

    if (!endpoint || !token || railsEnv !== "production") return;

    const userData = getMetaJSON("user-data");

    window.op = new OpenPanel({
      apiUrl: endpoint,
      clientId: token,
      disabled: false,
      trackScreenViews: true,
      trackOutgoingLinks: true,
      trackAttributes: true,
    });

    if (userData && userData.id) {
      window.op.identify({
        profileId: userData.id,
        firstName: userData.full_name,
        email: userData.email,
        properties: {
          account_id: userData.account_id,
          account_name: userData.account_name,
        },
      });
    }
  }
}
