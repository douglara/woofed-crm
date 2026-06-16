import { Controller } from "@hotwired/stimulus";

// Drives the WhatsApp template UI inside the Chatwoot message form.
// All template data is synced into `inboxesValue`, so the form renders fully
// client-side: picking an official WhatsApp inbox reveals a free-text/template
// toggle; picking a template renders its BODY variables, HEADER media input and
// dynamic BUTTON parameters. Generated inputs are named so they nest under
// event[additional_attributes][...] and map to the Event template helpers.
export default class extends Controller {
  static targets = [
    "inboxSelect",
    "templateMode",
    "modeToggle",
    "templateSection",
    "templateSelect",
    "bodyParams",
    "headerMedia",
    "buttonParams",
    "preview",
    "contentSection",
  ];
  static values = { inboxes: Array, saved: Object };

  connect() {
    // On edit, the inbox select is not pre-selected by Rails (jsonb hash), so
    // restore it from the saved value before deriving the rest of the state.
    if (this.savedValue.inbox_id && this.hasInboxSelectTarget) {
      this.inboxSelectTarget.value = String(this.savedValue.inbox_id);
    }
    this.inboxChanged();
  }

  inboxChanged() {
    const inbox = this.selectedInbox();
    const isWhatsapp = inbox && inbox.channel_type === "Channel::Whatsapp";

    this.modeToggleTarget.hidden = !isWhatsapp;
    if (!isWhatsapp) {
      this.useFreeText();
      return;
    }
    this.populateTemplates(inbox);
    this.applyMode();
  }

  // Free-text vs template radio toggle.
  modeChanged() {
    this.applyMode();
  }

  applyMode() {
    if (this.isTemplateMode()) {
      this.contentSectionTarget.hidden = true;
      this.templateSectionTarget.hidden = false;
      this.templateChanged();
    } else {
      this.useFreeText();
    }
  }

  useFreeText() {
    this.contentSectionTarget.hidden = false;
    this.templateSectionTarget.hidden = true;
    this.templateSelectTarget.value = "";
    this.clearDynamicFields();
  }

  populateTemplates(inbox) {
    // On edit, restore the saved template; otherwise keep the current selection.
    const desired = this.templateSelectTarget.value || this.savedValue.template_name || "";
    const options = ['<option value="">—</option>'];
    (inbox.message_templates || []).forEach((t) => {
      options.push(`<option value="${t.name}">${t.name}</option>`);
    });
    this.templateSelectTarget.innerHTML = options.join("");
    this.templateSelectTarget.value = desired;
  }

  templateChanged() {
    this.clearDynamicFields();
    const template = this.selectedTemplate();
    if (!template) return;

    const components = template.components || [];
    this.renderBodyParams(components);
    this.renderHeaderMedia(components);
    this.renderButtonParams(components);
    this.updatePreview();
  }

  renderBodyParams(components) {
    const body = components.find((c) => c.type === "BODY");
    if (!body) return;
    const examples = (body.example && body.example.body_text && body.example.body_text[0]) || [];
    const saved = this.savedValue.body_params || {};
    this.bodyVarIndexes(body.text).forEach((index, position) => {
      this.bodyParamsTarget.appendChild(
        this.field(
          `event[additional_attributes][template_body_params][${index}]`,
          `Variável {{${index}}}`,
          examples[position] || "",
          saved[index] || "",
          "body-param",
        ),
      );
    });
  }

  renderHeaderMedia(components) {
    const header = components.find((c) => c.type === "HEADER");
    if (!this.isMediaHeader(header)) return;
    this.headerMediaTarget.appendChild(
      this.field(
        "event[additional_attributes][template_header_media_url]",
        `URL da mídia (${header.format.toLowerCase()})`,
        "https://...",
        this.savedValue.header_media_url || "",
      ),
    );
  }

  renderButtonParams(components) {
    const saved = this.savedValue.button_params || {};
    this.dynamicButtons(components).forEach((button, index) => {
      this.buttonParamsTarget.appendChild(
        this.field(
          `event[additional_attributes][template_button_params][${index}]`,
          `Parâmetro do botão "${button.text}"`,
          "",
          saved[index] || "",
        ),
      );
    });
  }

  updatePreview() {
    if (!this.hasPreviewTarget) return;
    const template = this.selectedTemplate();
    const body = (template.components || []).find((c) => c.type === "BODY");
    let text = (body && body.text) || "";
    this.bodyParamsTarget.querySelectorAll("input").forEach((input) => {
      const index = input.name.match(/\[template_body_params\]\[(\d+)\]/)[1];
      text = text.replace(`{{${index}}}`, input.value || `{{${index}}}`);
    });
    this.previewTarget.textContent = text;
  }

  // --- helpers -------------------------------------------------------------

  selectedInbox() {
    const select = this.hasInboxSelectTarget
      ? this.inboxSelectTarget
      : this.element.querySelector("select[name*='chatwoot_inbox_id']");
    const id = select ? select.value : null;
    return this.inboxesValue.find((i) => String(i.id) === String(id));
  }

  selectedTemplate() {
    const inbox = this.selectedInbox();
    if (!inbox) return null;
    return (inbox.message_templates || []).find((t) => t.name === this.templateSelectTarget.value);
  }

  isTemplateMode() {
    const radio = this.templateModeTargets.find((r) => r.checked);
    return radio ? radio.value === "template" : false;
  }

  bodyVarIndexes(text) {
    const matches = (text || "").match(/\{\{(\d+)\}\}/g) || [];
    return [...new Set(matches.map((m) => m.replace(/\D/g, "")))];
  }

  isMediaHeader(header) {
    return header && ["IMAGE", "VIDEO", "DOCUMENT"].includes(header.format);
  }

  dynamicButtons(components) {
    const buttons = components.find((c) => c.type === "BUTTONS");
    return ((buttons && buttons.buttons) || []).filter(
      (b) => b.type === "URL" && /\{\{\d+\}\}/.test(b.url || ""),
    );
  }

  clearDynamicFields() {
    [this.bodyParamsTarget, this.headerMediaTarget, this.buttonParamsTarget].forEach((el) => {
      el.innerHTML = "";
    });
    if (this.hasPreviewTarget) this.previewTarget.textContent = "";
  }

  field(name, label, placeholder, value, action) {
    const wrapper = document.createElement("div");
    wrapper.className = "space-y-1 mt-2";
    const labelEl = document.createElement("label");
    labelEl.className = "typography-text-s-lh150 text-dark-gray-palette-p1";
    labelEl.textContent = label;
    const input = document.createElement("input");
    input.type = "text";
    input.name = name;
    input.placeholder = placeholder;
    input.value = value || "";
    input.className = "form-input w-full";
    if (action === "body-param") {
      input.setAttribute("data-action", "input->chatwoot-template-form#updatePreview");
    }
    wrapper.appendChild(labelEl);
    wrapper.appendChild(input);
    return wrapper;
  }
}
