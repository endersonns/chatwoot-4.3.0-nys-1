# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join 'spec/models/concerns/reauthorizable_shared.rb'

RSpec.describe Channel::Whatsapp, type: :model do
  describe 'concerns' do
    let(:channel) { create(:channel_whatsapp) }

    before do
      stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
    end

    it_behaves_like 'reauthorizable'

    context 'when prompt_reauthorization!' do
      it 'calls channel notifier mail for whatsapp' do
        admin_mailer = double
        mailer_double = double

        expect(AdministratorNotifications::ChannelNotificationsMailer).to receive(:with).and_return(admin_mailer)
        expect(admin_mailer).to receive(:whatsapp_disconnect).with(channel.inbox).and_return(mailer_double)
        expect(mailer_double).to receive(:deliver_later)

        channel.prompt_reauthorization!
      end
    end
  end

  describe 'validate_provider_config' do
    let(:channel) { build(:channel_whatsapp, provider: 'whatsapp_cloud', account: create(:account)) }

    it 'validates false when provider config is wrong' do
      stub_request(:get, 'https://graph.facebook.com/v14.0//message_templates?access_token=test_key').to_return(status: 401)
      expect(channel.save).to be(false)
    end

    it 'validates true when provider config is right' do
      stub_request(:get, 'https://graph.facebook.com/v14.0//message_templates?access_token=test_key')
        .to_return(status: 200,
                   body: { data: [{
                     id: '123456789', name: 'test_template'
                   }] }.to_json)
      expect(channel.save).to be(true)
    end
  end

  describe 'webhook_verify_token' do
    it 'generates webhook_verify_token if not present' do
      channel = create(:channel_whatsapp, provider_config: { webhook_verify_token: nil }, provider: 'whatsapp_cloud', account: create(:account),
                                          validate_provider_config: false, sync_templates: false)

      expect(channel.provider_config['webhook_verify_token']).not_to be_nil
    end

    it 'does not generate webhook_verify_token if present' do
      channel = create(:channel_whatsapp, provider: 'whatsapp_cloud', provider_config: { webhook_verify_token: '123' }, account: create(:account),
                                          validate_provider_config: false, sync_templates: false)

      expect(channel.provider_config['webhook_verify_token']).to eq '123'
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:phone_number) }
    it { is_expected.to validate_inclusion_of(:provider).in_array(%w[default whatsapp_cloud evolution_api]) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to have_one(:inbox).dependent(:destroy_async) }
  end

  describe 'callbacks' do
    describe 'before_destroy' do
      context 'when provider is evolution_api' do
        let(:whatsapp_channel) do
          create(:channel_whatsapp, provider: 'evolution_api', provider_config: { instance_id: 'test_instance_123' })
        end

        it 'calls delete_instance on provider service' do
          service = instance_double(Whatsapp::Providers::WhatsappEvolutionApiService)
          allow(Whatsapp::Providers::WhatsappEvolutionApiService).to receive(:new).and_return(service)
          allow(service).to receive(:delete_instance)

          whatsapp_channel.destroy!

          expect(service).to have_received(:delete_instance).with('test_instance_123')
        end

        it 'logs error and continues deletion if delete_instance fails' do
          service = instance_double(Whatsapp::Providers::WhatsappEvolutionApiService)
          allow(Whatsapp::Providers::WhatsappEvolutionApiService).to receive(:new).and_return(service)
          allow(service).to receive(:delete_instance).and_raise(StandardError, 'API Error')
          allow(Rails.logger).to receive(:error)

          expect { whatsapp_channel.destroy! }.not_to raise_error
          expect(Rails.logger).to have_received(:error).with(/Failed to delete Evolution API instance/)
        end

        it 'does not call delete_instance if instance_id is not present' do
          whatsapp_channel.update!(provider_config: {})
          service = instance_double(Whatsapp::Providers::WhatsappEvolutionApiService)
          allow(Whatsapp::Providers::WhatsappEvolutionApiService).to receive(:new).and_return(service)
          allow(service).to receive(:delete_instance)

          whatsapp_channel.destroy!

          expect(service).not_to have_received(:delete_instance)
        end
      end

      context 'when provider is not evolution_api' do
        let(:whatsapp_channel) { create(:channel_whatsapp, provider: 'whatsapp_cloud') }

        it 'does not call delete_instance' do
          service = instance_double(Whatsapp::Providers::WhatsappCloudService)
          allow(Whatsapp::Providers::WhatsappCloudService).to receive(:new).and_return(service)
          allow(service).to receive(:delete_instance)

          whatsapp_channel.destroy!

          expect(service).not_to have_received(:delete_instance)
        end
      end
    end
  end

  describe '#provider_service' do
    context 'when provider is whatsapp_cloud' do
      let(:whatsapp_channel) { build(:channel_whatsapp, provider: 'whatsapp_cloud') }

      it 'returns WhatsappCloudService' do
        expect(whatsapp_channel.provider_service).to be_a(Whatsapp::Providers::WhatsappCloudService)
      end
    end

    context 'when provider is evolution_api' do
      let(:whatsapp_channel) { build(:channel_whatsapp, provider: 'evolution_api') }

      it 'returns WhatsappEvolutionApiService' do
        expect(whatsapp_channel.provider_service).to be_a(Whatsapp::Providers::WhatsappEvolutionApiService)
      end
    end

    context 'when provider is default' do
      let(:whatsapp_channel) { build(:channel_whatsapp, provider: 'default') }

      it 'returns Whatsapp360DialogService' do
        expect(whatsapp_channel.provider_service).to be_a(Whatsapp::Providers::Whatsapp360DialogService)
      end
    end
  end
end
