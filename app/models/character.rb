# frozen_string_literal: true

class Character < ApplicationRecord
  belongs_to :story
  has_many :players

  validates :name, presence: true
  validates :gender, presence: true
end
