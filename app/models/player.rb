# frozen_string_literal: true

class Player < ApplicationRecord
  belongs_to :room
  belongs_to :character
end
