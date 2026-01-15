// Load all the controllers within this directory and all subdirectories.
// Controller files must be named *_controller.js or *_controller.ts.

import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Webpack 5 - usar import.meta.webpackContext em vez de require.context
const controllers = import.meta.webpackContext(".", {
  recursive: true,
  regExp: /_controller\.js$/,
})

controllers.keys().forEach((filename) => {
  const controllerModule = controllers(filename)
  
  // Converter nome do arquivo para identificador do Stimulus
  // Ex: "./modal_controller.js" -> "modal"
  // Ex: "./form/search_controller.js" -> "form--search"
  const identifier = filename
    .replace("./", "")
    .replace(/_controller\.js$/, "")
    .replace(/\//g, "--")
    .replace(/_/g, "-")
  
  application.register(identifier, controllerModule.default)
})

window.Stimulus = application
