require 'rails_helper'

RSpec.describe Api::V1::Accounts::Channels::EvolutionApiController, type: :controller do
  let(:account) { create(:account) }
  let(:user) { create(:user, account: account, role: :administrator) }

  before do
    sign_in(user)
  end

  describe 'POST #create_instance' do
    let(:params) do
      {
        account_id: account.id,
        instance_name: 'test_instance',
        phone_number: '5511999999999'
      }
    end

    it 'creates an instance successfully' do
      service = instance_double(Whatsapp::Providers::WhatsappEvolutionApiService)
      allow(Whatsapp::Providers::WhatsappEvolutionApiService).to receive(:new).and_return(service)
      allow(service).to receive(:create_instance).and_return({ 'id' => 'instance_123' })

      post :create_instance, params: params

      expect(response).to have_http_status(:created)
      expect(JSON.parse(response.body)['instance_id']).to eq('instance_123')
    end

    it 'returns error when service fails' do
      service = instance_double(Whatsapp::Providers::WhatsappEvolutionApiService)
      allow(Whatsapp::Providers::WhatsappEvolutionApiService).to receive(:new).and_return(service)
      allow(service).to receive(:create_instance).and_raise(StandardError, 'API Error')

      post :create_instance, params: params

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to eq('API Error')
    end
  end

  describe 'GET #qrcode' do
    let(:params) do
      {
        account_id: account.id,
        id: 'instance_123'
      }
    end

    it 'fetches QR code successfully' do
      service = instance_double(Whatsapp::Providers::WhatsappEvolutionApiService)
      allow(Whatsapp::Providers::WhatsappEvolutionApiService).to receive(:new).and_return(service)
      allow(service).to receive(:fetch_qr_code).and_return({
        'qr_code_url' => 'https://example.com/qr.png',
        'connected' => false
      })

      get :qrcode, params: params

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['qr_code_url']).to eq('https://example.com/qr.png')
      expect(JSON.parse(response.body)['connected']).to eq(false)
    end

    it 'returns error when service fails' do
      service = instance_double(Whatsapp::Providers::WhatsappEvolutionApiService)
      allow(Whatsapp::Providers::WhatsappEvolutionApiService).to receive(:new).and_return(service)
      allow(service).to receive(:fetch_qr_code).and_raise(StandardError, 'API Error')

      get :qrcode, params: params

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to eq('API Error')
    end
  end

  describe 'POST #logout' do
    let(:params) do
      {
        account_id: account.id,
        id: 'instance_123'
      }
    end

    it 'logs out instance successfully' do
      service = instance_double(Whatsapp::Providers::WhatsappEvolutionApiService)
      allow(Whatsapp::Providers::WhatsappEvolutionApiService).to receive(:new).and_return(service)
      allow(service).to receive(:logout_instance).and_return({ 'success' => true })

      post :logout, params: params

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['success']).to eq(true)
    end

    it 'returns error when service fails' do
      service = instance_double(Whatsapp::Providers::WhatsappEvolutionApiService)
      allow(Whatsapp::Providers::WhatsappEvolutionApiService).to receive(:new).and_return(service)
      allow(service).to receive(:logout_instance).and_raise(StandardError, 'API Error')

      post :logout, params: params

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to eq('API Error')
    end
  end

  describe 'DELETE #destroy' do
    let(:params) do
      {
        account_id: account.id,
        id: 'instance_123'
      }
    end

    it 'deletes instance successfully' do
      service = instance_double(Whatsapp::Providers::WhatsappEvolutionApiService)
      allow(Whatsapp::Providers::WhatsappEvolutionApiService).to receive(:new).and_return(service)
      allow(service).to receive(:delete_instance).and_return({ 'success' => true })

      delete :destroy, params: params

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['success']).to eq(true)
    end

    it 'returns error when service fails' do
      service = instance_double(Whatsapp::Providers::WhatsappEvolutionApiService)
      allow(Whatsapp::Providers::WhatsappEvolutionApiService).to receive(:new).and_return(service)
      allow(service).to receive(:delete_instance).and_raise(StandardError, 'API Error')

      delete :destroy, params: params

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)['error']).to eq('API Error')
    end
  end
end 