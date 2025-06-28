class Api::V1::Accounts::Channels::EvolutionApiController < Api::V1::Accounts::BaseController
  before_action :set_service

  # POST /api/v1/accounts/:account_id/channels/evolution_api/instances
  def create_instance
    instance_name = params[:instance_name]
    phone_number = params[:phone_number]
    result = @service.create_instance(instance_name: instance_name, phone_number: phone_number)
    render json: { instance_id: result['id'] }, status: :created
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/channels/evolution_api/instances/:id/qrcode
  def qrcode
    instance_id = params[:id]
    result = @service.fetch_qr_code(instance_id)
    render json: { qr_code_url: result['qr_code_url'], connected: result['connected'] }, status: :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/accounts/:account_id/channels/evolution_api/instances/:id/logout
  def logout
    instance_id = params[:id]
    @service.logout_instance(instance_id)
    render json: { success: true }, status: :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # DELETE /api/v1/accounts/:account_id/channels/evolution_api/instances/:id
  def destroy
    instance_id = params[:id]
    @service.delete_instance(instance_id)
    render json: { success: true }, status: :ok
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_service
    # Pode customizar para buscar config global do super admin futuramente
    @service = Whatsapp::Providers::WhatsappEvolutionApiService.new(whatsapp_channel: nil)
  end
end 