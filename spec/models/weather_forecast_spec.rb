require 'rails_helper'

RSpec.describe WeatherForecast, type: :model do
  describe 'validations' do
    subject(:forecast) { described_class.new(attributes) }

    let(:valid_attributes) do
      {
        location: '90210',
        current_temp: 20.5,
        high_temp: 25.0,
        low_temp: 15.0,
        conditions: 'Sunny'
      }
    end

    context 'with valid attributes' do
      let(:attributes) { valid_attributes }
      let(:expected_attributes) { attributes.stringify_keys }
      let(:actual_attributes) do
        forecast.attributes.slice(*expected_attributes.stringify_keys.keys)
      end

      it 'is valid' do
        expect(forecast).to be_valid
      end

      it 'sets all attributes correctly' do
        expect(actual_attributes).to eq(expected_attributes)
      end
    end

    context 'with missing attributes' do
      before { forecast.valid? }

      let(:attributes) { {} }

      it "is invalid" do
        expect(forecast).not_to be_valid
      end

      it 'is invalid without location' do
        expect(forecast.errors[:location]).to include("can't be blank")
      end

      it 'is invalid without current_temp' do
        expect(forecast.errors[:current_temp]).to include("can't be blank")
      end

      it 'is invalid without high_temp' do
        expect(forecast.errors[:high_temp]).to include("can't be blank")
      end

      it 'is invalid without low_temp' do
        expect(forecast.errors[:low_temp]).to include("can't be blank")
      end

      it 'is invalid without conditions' do
        expect(forecast.errors[:conditions]).to include("can't be blank")
      end
    end

    context 'with invalid temperature values' do
      before { forecast.valid? }

      let(:attributes)  do
        valid_attributes.merge({
          current_temp: 'not a number',
          high_temp: 'not a number',
          low_temp: 'not a number'
        })
      end

      it "is invalid" do
        expect(forecast).not_to be_valid
      end

      it 'is invalid with non-numeric current_temp' do
        expect(forecast.errors[:current_temp]).to include('is not a number')
      end

      it 'is invalid with non-numeric high_temp' do
        expect(forecast.errors[:high_temp]).to include('is not a number')
      end

      it 'is invalid with non-numeric low_temp' do
        expect(forecast.errors[:low_temp]).to include('is not a number')
      end
    end

    context 'with invalid temperature relationship' do
      let(:attributes) do
        valid_attributes.merge({
          high_temp: 15.0,
          low_temp: 25.0
        })
      end

      it 'is invalid when high_temp is less than or equal to low_temp' do
        expect(forecast).not_to be_valid
        expect(forecast.errors[:high_temp]).to include('must be greater than low temperature')
      end
    end
  end
end
