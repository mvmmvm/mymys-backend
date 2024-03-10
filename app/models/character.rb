class Character < ApplicationRecord
  belongs_to :story
  has_many :players
end
