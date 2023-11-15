import { Controller } from "stimulus"
import lucide from "lucide/dist/umd/lucide"

export default class extends Controller {
  connect() {
    lucide.createIcons();
  }
}
