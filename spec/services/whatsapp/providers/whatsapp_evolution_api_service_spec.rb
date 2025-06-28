require 'rails_helper'

RSpec.describe Whatsapp::Providers::WhatsappEvolutionApiService do
  let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'evolution_api') }
  let(:service) { described_class.new(whatsapp_channel: whatsapp_channel) }

  before do
    allow(ENV).to receive(:[]).with('EVOLUTION_API_KEY').and_return('test_api_key')
    allow(ENV).to receive(:[]).with('EVOLUTION_API_BASE_URL').and_return('https://api.evolution.com')
  end

  describe '#create_instance' do
    let(:instance_name) { 'test_instance' }
    let(:phone_number) { '5511999999999' }

    it 'creates an instance successfully' do
      response_body = { 'id' => 'instance_123', 'name' => instance_name }
      stub_request(:post, 'https://api.evolution.com/instances')
        .with(
          headers: {
            'Authorization' => 'Bearer test_api_key',
            'Content-Type' => 'application/json'
          },
          body: {
            name: instance_name,
            phone: phone_number
          }.to_json
        )
        .to_return(status: 200, body: response_body.to_json)

      result = service.create_instance(instance_name: instance_name, phone_number: phone_number)

      expect(result).to eq(response_body)
    end

    it 'raises error when API call fails' do
      stub_request(:post, 'https://api.evolution.com/instances')
        .to_return(status: 400, body: { error: 'Bad Request' }.to_json)

      expect do
        service.create_instance(instance_name: instance_name, phone_number: phone_number)
      end.to raise_error(StandardError, 'Bad Request')
    end
  end

  describe '#fetch_qr_code' do
    let(:instance_id) { 'instance_123' }

    it 'fetches QR code successfully' do
      response_body = {
        'qr_code_url' => 'https://example.com/qr.png',
        'connected' => false
      }
      stub_request(:get, "https://api.evolution.com/instances/#{instance_id}/qrcode")
        .with(headers: { 'Authorization' => 'Bearer test_api_key' })
        .to_return(status: 200, body: response_body.to_json)

      result = service.fetch_qr_code(instance_id)

      expect(result).to eq(response_body)
    end

    it 'raises error when API call fails' do
      stub_request(:get, "https://api.evolution.com/instances/#{instance_id}/qrcode")
        .to_return(status: 404, body: { error: 'Instance not found' }.to_json)

      expect do
        service.fetch_qr_code(instance_id)
      end.to raise_error(StandardError, 'Instance not found')
    end
  end

  describe '#logout_instance' do
    let(:instance_id) { 'instance_123' }

    it 'logs out instance successfully' do
      response_body = { 'success' => true }
      stub_request(:post, "https://api.evolution.com/instances/#{instance_id}/logout")
        .with(headers: { 'Authorization' => 'Bearer test_api_key' })
        .to_return(status: 200, body: response_body.to_json)

      result = service.logout_instance(instance_id)

      expect(result).to eq(response_body)
    end

    it 'raises error when API call fails' do
      stub_request(:post, "https://api.evolution.com/instances/#{instance_id}/logout")
        .to_return(status: 500, body: { error: 'Internal Server Error' }.to_json)

      expect do
        service.logout_instance(instance_id)
      end.to raise_error(StandardError, 'Internal Server Error')
    end
  end

  describe '#delete_instance' do
    let(:instance_id) { 'instance_123' }

    it 'deletes instance successfully' do
      response_body = { 'success' => true }
      stub_request(:delete, "https://api.evolution.com/instances/#{instance_id}")
        .with(headers: { 'Authorization' => 'Bearer test_api_key' })
        .to_return(status: 200, body: response_body.to_json)

      result = service.delete_instance(instance_id)

      expect(result).to eq(response_body)
    end

    it 'raises error when API call fails' do
      stub_request(:delete, "https://api.evolution.com/instances/#{instance_id}")
        .to_return(status: 404, body: { error: 'Instance not found' }.to_json)

      expect do
        service.delete_instance(instance_id)
      end.to raise_error(StandardError, 'Instance not found')
    end
  end

  describe '#validate_provider_config?' do
    context 'when API key and base URL are present' do
      it 'returns true' do
        expect(service.validate_provider_config?).to be true
      end
    end

    context 'when API key is missing' do
      before do
        allow(ENV).to receive(:[]).with('EVOLUTION_API_KEY').and_return(nil)
        allow(whatsapp_channel).to receive(:provider_config).and_return({})
      end

      it 'returns false' do
        expect(service.validate_provider_config?).to be false
      end
    end

    context 'when base URL is missing' do
      before do
        allow(ENV).to receive(:[]).with('EVOLUTION_API_BASE_URL').and_return(nil)
        allow(whatsapp_channel).to receive(:provider_config).and_return({})
      end

      it 'returns false' do
        expect(service.validate_provider_config?).to be false
      end
    end
  end

  describe '#api_headers' do
    it 'returns correct headers' do
      expect(service.api_headers).to eq({
        'Authorization' => 'Bearer test_api_key',
        'Content-Type' => 'application/json'
      })
    end
  end

  describe '#api_key' do
    context 'when ENV variable is set' do
      it 'returns ENV value' do
        expect(service.api_key).to eq('test_api_key')
      end
    end

    context 'when ENV variable is not set' do
      before do
        allow(ENV).to receive(:[]).with('EVOLUTION_API_KEY').and_return(nil)
        allow(whatsapp_channel).to receive(:provider_config).and_return({ 'api_key' => 'channel_api_key' })
      end

      it 'returns channel config value' do
        expect(service.api_key).to eq('channel_api_key')
      end
    end
  end

  describe '#api_base_url' do
    context 'when ENV variable is set' do
      it 'returns ENV value' do
        expect(service.api_base_url).to eq('https://api.evolution.com')
      end
    end

    context 'when ENV variable is not set' do
      before do
        allow(ENV).to receive(:[]).with('EVOLUTION_API_BASE_URL').and_return(nil)
        allow(whatsapp_channel).to receive(:provider_config).and_return({ 'api_base_url' => 'https://custom.api.com' })
      end

      it 'returns channel config value' do
        expect(service.api_base_url).to eq('https://custom.api.com')
      end
    end
  end
end 