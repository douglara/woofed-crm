# frozen_string_literal: true

require "rails_helper"

RSpec.describe Plugins::Adapters::JsAst do
  before { Plugins::FilePatch.clear_registry! }
  after  { Plugins::FilePatch.clear_registry! }

  let(:jsx_content) do
    <<~JSX
      import React, { useState } from "react"
      import Avatar from "@/components/Avatar"

      export default function UserProfile({ user }) {
        const [tab, setTab] = useState("info")

        return (
          <div className="user-profile">
            <h1 className="user-name">{user.name}</h1>

            <div className="tabs">
              <button onClick={() => setTab("info")}>Info</button>
              {/* plugin:tabs */}
            </div>

            <div className="tab-content">
              {tab === "info" && <InfoTab user={user} />}
              {/* plugin:tab-content */}
            </div>
          </div>
        )
      }
    JSX
  end

  describe "JSX patching" do
    it "adds imports and tab content" do
      patch = Plugins::FilePatch.define(target: "app/javascript/pages/UserProfile.jsx") do
        after_line containing: 'import Avatar from "@/components/Avatar"' do
          'import ExampleBadge from "@/components/ExampleBadge"'
        end

        after_line containing: "{/* plugin:tabs */}" do
          '        <button onClick={() => setTab("example")}>Example</button>'
        end

        after_line containing: "{/* plugin:tab-content */}" do
          '        {tab === "example" && <ExampleBadge userId={user.id} />}'
        end
      end

      result = patch.apply_to(jsx_content)

      expect(result).to include('import ExampleBadge from "@/components/ExampleBadge"')
      expect(result).to include('setTab("example")}>Example</button>')
      expect(result).to include('tab === "example" && <ExampleBadge userId={user.id} />')
    end
  end

  describe "TypeScript files" do
    let(:ts_content) do
      <<~TS
        interface User {
          id: number
          name: string
        }

        export function greet(user: User): string {
          return `Hello, ${user.name}`
        }
      TS
    end

    it "patches TypeScript files" do
      patch = Plugins::FilePatch.define(target: "app/javascript/utils/greet.ts") do
        after_line containing: "name: string" do
          "  email: string"
        end
      end

      result = patch.apply_to(ts_content)
      expect(result).to include("email: string")
    end
  end
end
