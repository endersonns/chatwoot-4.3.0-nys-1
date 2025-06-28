import ApiClient from '../ApiClient';

class EvolutionApiChannel extends ApiClient {
  constructor() {
    super('channels/evolution_api', { accountScoped: true });
  }

  createInstance(data) {
    return this.create('instances', data);
  }

  fetchQrCode(instanceId) {
    return this.show(`instances/${instanceId}/qrcode`);
  }

  logout(instanceId) {
    return this.create(`instances/${instanceId}/logout`);
  }

  deleteInstance(instanceId) {
    return this.delete(`instances/${instanceId}`);
  }
}

export default new EvolutionApiChannel(); 