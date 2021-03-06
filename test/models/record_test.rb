require 'test_helper'

class RecordTest < ActiveSupport::TestCase
  context "associations" do
    should belong_to(:competition)
    should belong_to(:heat)
  end

  context "validations" do
    should validate_presence_of(:competition_id)
    should validate_presence_of(:heat_id)
  end
end
