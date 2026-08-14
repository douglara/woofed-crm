# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plugins::Adapters do
  describe ".adapter_for" do
    it "returns TextLine for .rb files" do
      expect(described_class.adapter_for("app/models/contact.rb")).to eq(Plugins::Adapters::TextLine)
    end

    it "returns TextLine for .erb files" do
      expect(described_class.adapter_for("app/views/users/show.html.erb")).to eq(Plugins::Adapters::TextLine)
    end

    it "returns TextLine for .css files" do
      expect(described_class.adapter_for("app/assets/stylesheets/app.css")).to eq(Plugins::Adapters::TextLine)
    end

    it "returns JsAst for .js files" do
      expect(described_class.adapter_for("app/javascript/app.js")).to eq(Plugins::Adapters::JsAst)
    end

    it "returns JsAst for .jsx files" do
      expect(described_class.adapter_for("app/javascript/pages/Profile.jsx")).to eq(Plugins::Adapters::JsAst)
    end

    it "returns JsAst for .ts files" do
      expect(described_class.adapter_for("app/javascript/utils/helper.ts")).to eq(Plugins::Adapters::JsAst)
    end

    it "returns JsAst for .tsx files" do
      expect(described_class.adapter_for("app/javascript/pages/Dashboard.tsx")).to eq(Plugins::Adapters::JsAst)
    end
  end
end
