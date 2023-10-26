import { Controller } from "stimulus"
import "flowbite/dist/flowbite.turbo.js";

export default class extends Controller {
    connect() {
        initDismisses();
        initDropdowns();
    }
}
