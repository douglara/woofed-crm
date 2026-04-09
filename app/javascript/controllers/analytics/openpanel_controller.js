import { Controller } from "@hotwired/stimulus";
import { OpenPanel } from "@openpanel/web";
import { getMetaContent, getRailsEnvironment } from "../../utils/meta";
import { currentUser, isLoggedIn } from "../../utils/current_user";

export default class extends Controller {
  connect() {
    if (window.op) return;

    const railsEnv = getRailsEnvironment();
    const endpoint = getMetaContent("openpanel-endpoint");
    const token = getMetaContent("openpanel-token");

    if (!endpoint || !token || railsEnv !== "production") return;

    window.op = new OpenPanel({
      apiUrl: endpoint,
      clientId: token,
      disabled: false,
      trackScreenViews: true,
      trackOutgoingLinks: true,
      trackAttributes: true,
    });

    if (isLoggedIn()) {
      const user = currentUser();
      window.op.identify({
        profileId: user.id,
        firstName: user.full_name,
        email: user.email,
        properties: {
          account_id: user.account_id,
          account_name: user.account_name,
        },
      });
    }
  }
}
