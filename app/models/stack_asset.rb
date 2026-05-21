class StackAsset < ApplicationRecord
  has_many :bids, dependent: :destroy

  validates :name, presence: true
  validates :status, inclusion: { in: %w[active_auction owned draft] }
  validates :risk_level, inclusion: { in: %w[Low Medium High] }

  def technologies_list
    technologies.to_s.split(',').map(&:strip)
  end
end

