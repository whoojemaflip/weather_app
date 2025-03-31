class WeatherForecast
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  class TemperatureType < ActiveModel::Type::Float
    def cast(value)
      return nil if value.blank?
      return value if value.is_a?(Numeric)
      return nil unless value.to_s.match?(/\A[+-]?\d+(\.\d+)?\z/)
      super
    end
  end

  attribute :location, :string
  attribute :current_temp, TemperatureType.new
  attribute :high_temp, TemperatureType.new
  attribute :low_temp, TemperatureType.new
  attribute :conditions, :string

  validates :location, presence: true
  validates :current_temp, presence: true, numericality: true
  validates :high_temp, presence: true, numericality: true
  validates :low_temp, presence: true, numericality: true
  validates :conditions, presence: true

  validate :high_temp_greater_than_low_temp

  private

  def high_temp_greater_than_low_temp
    return if high_temp.blank? || low_temp.blank?

    if high_temp <= low_temp
      errors.add(:high_temp, "must be greater than low temperature")
    end
  end
end
