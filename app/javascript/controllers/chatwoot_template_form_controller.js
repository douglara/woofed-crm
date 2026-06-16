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
  static values = { inboxes: Array, saved: Object, mergeFields: Array };

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
        this.bodyParamField(index, examples[position] || "", saved[index] || ""),
      );
    });
  }

  // A body variable input with a "source" selector: a fixed text, or a contact
  // field that is resolved per lead at send time (a {{contact.<field>}} token).
  // This is what makes a bulk send personalised (e.g. {{1}} = each lead's name).
  bodyParamField(index, example, saved) {
    const wrapper = document.createElement("div");
    wrapper.className = "space-y-1 mt-2";
    const labelEl = document.createElement("label");
    labelEl.className = "typography-text-s-lh150 text-dark-gray-palette-p1";
    labelEl.textContent = `Variável {{${index}}}`;

    const row = document.createElement("div");
    row.className = "flex gap-2";

    const select = document.createElement("select");
    select.className = "form-input";
    select.innerHTML =
      `<option value="">${this.fixedTextLabel()}</option>` +
      this.mergeFields()
        .map((f) => `<option value="${f.key}">${f.label}</option>`)
        .join("");

    const input = document.createElement("input");
    input.type = "text";
    input.name = `event[additional_attributes][template_body_params][${index}]`;
    input.placeholder = example || "";
    input.className = "form-input w-full";
    input.setAttribute("data-action", "input->chatwoot-template-form#updatePreview");

    const applyContactField = (field) => {
      input.value = `{{contact.${field}}}`;
      input.readOnly = true;
      input.classList.add("bg-light-palette-p4");
    };
    const applyFixedText = (value) => {
      input.value = value || "";
      input.readOnly = false;
      input.classList.remove("bg-light-palette-p4");
    };

    const token = this.parseMergeToken(saved);
    if (token) {
      select.value = token;
      applyContactField(token);
    } else {
      applyFixedText(saved);
    }

    select.addEventListener("change", () => {
      if (select.value) applyContactField(select.value);
      else applyFixedText("");
      this.updatePreview();
    });

    row.appendChild(select);
    row.appendChild(input);
    wrapper.appendChild(labelEl);
    wrapper.appendChild(row);
    return wrapper;
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
      const token = this.parseMergeToken(input.value);
      const shown = token ? `«${this.mergeFieldLabel(token)}»` : input.value || `{{${index}}}`;
      text = text.replace(`{{${index}}}`, shown);
    });
    this.previewTarget.textContent = text;
  }

  // --- merge tags ----------------------------------------------------------

  // Contact fields offered as merge tags. Can be overridden from the view via
  // data-…-merge-fields-value (e.g. to add custom attributes); falls back to the
  // standard fields, which the Event model resolves server-side.
  mergeFields() {
    return this.hasMergeFieldsValue && this.mergeFieldsValue.length
      ? this.mergeFieldsValue
      : [
          { key: "full_name", label: "Nome do contato" },
          { key: "phone", label: "Telefone" },
          { key: "email", label: "Email" },
        ];
  }

  fixedTextLabel() {
    return "Texto fixo";
  }

  parseMergeToken(value) {
    const m = (value || "").match(/^\{\{\s*contact\.([a-z_]+(?:\.[A-Za-z0-9_ -]+)?)\s*\}\}$/);
    return m ? m[1] : null;
  }

  mergeFieldLabel(key) {
    const field = this.mergeFields().find((f) => f.key === key);
    return field ? field.label : key;
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
