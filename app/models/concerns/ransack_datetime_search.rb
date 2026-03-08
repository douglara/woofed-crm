# frozen_string_literal: true

# Converts datetime columns to date in the user's timezone for Ransack searches.
# Based on: https://github.com/activerecord-hackery/ransack/wiki/Using-Ransackers#search-using-datetime
#
# When included, provides a class method to define date-aware ransackers for
# datetime columns using PostgreSQL's AT TIME ZONE conversion.
#
# Requires Time.zone to be set to the user's timezone before calling Ransack
# (e.g., via Time.use_zone in Query::Filter).
#
# Usage:
#   class Deal < ApplicationRecord
#     include RansackDatetimeSearch
#     ransack_date_search :created_at, :updated_at, :won_at, :lost_at
#   end
module RansackDatetimeSearch
  extend ActiveSupport::Concern

  class_methods do
    def ransack_date_search(*attrs)
      attrs.each do |attr|
        ransacker attr, type: :date do
          Arel.sql("date(#{table_name}.#{attr} at time zone 'UTC' at time zone '#{Time.zone.name}')")
        end
      end
    end
  end
end
