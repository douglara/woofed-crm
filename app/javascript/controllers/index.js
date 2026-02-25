// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js or *_controller.ts.
import { Application } from "@hotwired/stimulus";
import { registerControllers } from "stimulus-vite-helpers";

const application = Application.start();
const controllers = import.meta.glob("./**/*_controller.{js,ts}", {
  eager: true,
});
registerControllers(application, controllers);
