# frozen_string_literal: true

class MoveWoofbotToAiAssistentsModel < ActiveRecord::Migration[7.1]
  def up
    Account.find_each do |account|
      if account.woofbot_auto_reply == true || account.ai_usage['tokens'].positive?
        Apps::AiAssistent.create!(
          model: 'gpt-4o',
          auto_reply: account.woofbot_auto_reply,
          usage: account.ai_usage.slice('tokens')
        )
      end
    end
  end

  def down
    Apps::AiAssistent.find_each(&:destroy!)
  end
end
