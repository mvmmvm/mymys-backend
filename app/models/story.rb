# frozen_string_literal: true

class Story < ApplicationRecord
  has_many :rooms
  has_many :characters
end
