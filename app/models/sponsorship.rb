class Sponsorship < ApplicationRecord
  belongs_to :funder, class_name: 'Account'
  belongs_to :maintainer, class_name: 'Account'

  scope :active, -> { where(status: 'active') }
  scope :inactive, -> { where(status: 'inactive') }
end
