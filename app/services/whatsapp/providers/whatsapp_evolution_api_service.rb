class Whatsapp::Providers::WhatsappEvolutionApiService < Whatsapp::Providers::BaseService
  require 'httparty'

  def create_instance(instance_name:, phone_number:)
    response = HTTParty.post(
      "#{api_base_url}/instances",
      headers: api_headers,
      body: {
        name: instance_name,
        phone: phone_number
      }.to_json
    )
    process_response(response)
  end

  def fetch_qr_code(instance_id)
    response = HTTParty.get(
      "#{api_base_url}/instances/#{instance_id}/qrcode",
      headers: api_headers
    )
    process_response(response)
  end

  def logout_instance(instance_id)
    response = HTTParty.post(
      "#{api_base_url}/instances/#{instance_id}/logout",
      headers: api_headers
    )
    process_response(response)
  end

  def delete_instance(instance_id)
    response = HTTParty.delete(
      "#{api_base_url}/instances/#{instance_id}",
      headers: api_headers
    )
    process_response(response)
  end

  def validate_provider_config?
    api_key.present? && api_base_url.present?
  end

  def api_headers
    {
      'Authorization' => "Bearer #{api_key}",
      'Content-Type' => 'application/json'
    }
  end

  def api_key
    ENV['EVOLUTION_API_KEY'] || whatsapp_channel.provider_config['api_key']
  end

  def api_base_url
    ENV['EVOLUTION_API_BASE_URL'] || whatsapp_channel.provider_config['api_base_url']
  end

  private

  def process_response(response)
    if response.success?
      response.parsed_response
    else
      raise StandardError, response.parsed_response['error'] || 'Erro na Evolution API'
    end
  end
end 