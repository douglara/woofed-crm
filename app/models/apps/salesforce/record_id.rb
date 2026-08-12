# frozen_string_literal: true

# Salesforce hands out two ids for the same record: a 15-character case-sensitive
# one, shown in record URLs and report exports, and an 18-character
# case-insensitive one returned by the API, whose three extra characters encode
# the capitalisation of the first fifteen.
#
# Both forms circulate, so everything is normalised to 18 before being written or
# looked up. Without it the same record could land twice in the mapping table and
# become two Woofed records -- the exact duplicate that table exists to prevent.
class Apps::Salesforce::RecordId
  SUFFIX_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345'

  def self.call(salesforce_id)
    id = salesforce_id.to_s.strip
    return id unless id.length == 15

    id + id.chars.each_slice(5).map { |chunk| SUFFIX_CHARS[uppercase_bits(chunk)] }.join
  end

  # Each group of five characters becomes a number whose bits say which of them
  # are uppercase, and that number indexes the 32-character suffix alphabet.
  def self.uppercase_bits(chunk)
    chunk.each_with_index.sum { |char, index| char.match?(/[A-Z]/) ? 2**index : 0 }
  end

  private_class_method :uppercase_bits
end
