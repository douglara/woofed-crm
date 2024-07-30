class ChangeFileTypeInAttachments < ActiveRecord::Migration[6.1]
  def change
    change_column_default :attachments, :file_type, from: 0, to: nil
    change_column_null :attachments, :file_type, true
  end
end
