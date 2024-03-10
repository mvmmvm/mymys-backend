class Room < ApplicationRecord
  belongs_to :story
  has_many :players
end
