<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      instanceName: '',
      phoneNumber: '',
      isCreating: false,
      showQrModal: false,
      qrCodeUrl: '',
      instanceId: '',
      qrInterval: null,
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'inboxes/getUIFlags' }),
  },
  validations: {
    instanceName: { required },
    phoneNumber: { required },
  },
  methods: {
    async createInstance() {
      this.v$.$touch();
      if (this.v$.$invalid) return;
      this.isCreating = true;
      try {
        // Chamada para backend criar instância Evolution API
        const response = await this.$store.dispatch('inboxes/createEvolutionInstance', {
          instance_name: this.instanceName,
          phone_number: this.phoneNumber,
        });
        this.instanceId = response.instance_id;
        this.showQrModal = true;
        this.fetchQrCode();
        this.qrInterval = setInterval(this.fetchQrCode, 10000);
      } catch (error) {
        useAlert(error.message || 'Erro ao criar instância Evolution API');
      } finally {
        this.isCreating = false;
      }
    },
    async fetchQrCode() {
      if (!this.instanceId) return;
      try {
        // Chamada para backend buscar QR Code
        const response = await this.$store.dispatch('inboxes/fetchEvolutionQrCode', {
          instance_id: this.instanceId,
        });
        this.qrCodeUrl = response.qr_code_url;
        if (response.connected) {
          clearInterval(this.qrInterval);
          this.showQrModal = false;
          // Salvar inbox após conexão
          await this.saveInbox();
        }
      } catch (error) {
        useAlert(error.message || 'Erro ao buscar QR Code');
      }
    },
    async saveInbox() {
      try {
        const inbox = await this.$store.dispatch('inboxes/createChannel', {
          name: this.instanceName,
          channel: {
            type: 'whatsapp',
            phone_number: this.phoneNumber,
            provider: 'evolution_api',
            provider_config: {
              instance_id: this.instanceId,
            },
          },
        });
        router.replace({
          name: 'settings_inboxes_add_agents',
          params: { page: 'new', inbox_id: inbox.id },
        });
      } catch (error) {
        useAlert(error.message || 'Erro ao salvar inbox Evolution API');
      }
    },
    closeQrModal() {
      this.showQrModal = false;
      clearInterval(this.qrInterval);
    },
  },
  beforeUnmount() {
    if (this.qrInterval) clearInterval(this.qrInterval);
  },
};
</script>

<template>
  <div class="w-full">
    <form @submit.prevent="createInstance" class="space-y-6">
      <div>
        <label for="instanceName" class="block text-sm font-medium text-slate-700">
          Nome da Instância
        </label>
        <input
          id="instanceName"
          v-model="instanceName"
          type="text"
          class="mt-1 block w-full rounded-md border-slate-300 shadow-sm focus:border-woot-500 focus:ring-woot-500 sm:text-sm"
          :class="{ 'border-red-300': v$.instanceName.$error }"
          placeholder="Digite o nome da instância"
        />
        <span v-if="v$.instanceName.$error" class="text-red-500 text-sm">
          Nome da instância é obrigatório
        </span>
      </div>

      <div>
        <label for="phoneNumber" class="block text-sm font-medium text-slate-700">
          Número de Telefone
        </label>
        <input
          id="phoneNumber"
          v-model="phoneNumber"
          type="text"
          class="mt-1 block w-full rounded-md border-slate-300 shadow-sm focus:border-woot-500 focus:ring-woot-500 sm:text-sm"
          :class="{ 'border-red-300': v$.phoneNumber.$error }"
          placeholder="Ex: 5511999999999"
        />
        <span v-if="v$.phoneNumber.$error" class="text-red-500 text-sm">
          Número de telefone é obrigatório
        </span>
      </div>

      <NextButton
        type="submit"
        :loading="isCreating"
        :disabled="isCreating"
        class="w-full"
      >
        {{ isCreating ? 'Criando Instância...' : 'Criar Instância' }}
      </NextButton>
    </form>

    <!-- Modal QR Code -->
    <div
      v-if="showQrModal"
      class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      @click="closeQrModal"
    >
      <div
        class="bg-white rounded-lg p-6 max-w-md w-full mx-4"
        @click.stop
      >
        <div class="text-center">
          <h3 class="text-lg font-medium text-slate-900 mb-4">
            Conecte seu WhatsApp
          </h3>
          <p class="text-sm text-slate-600 mb-4">
            Escaneie o QR Code com seu WhatsApp para conectar a instância
          </p>
          
          <div class="flex justify-center mb-4">
            <img
              v-if="qrCodeUrl"
              :src="qrCodeUrl"
              alt="QR Code WhatsApp"
              class="border border-slate-300 rounded-lg"
            />
            <div v-else class="w-48 h-48 bg-slate-100 rounded-lg flex items-center justify-center">
              <span class="text-slate-500">Carregando QR Code...</span>
            </div>
          </div>

          <div class="flex justify-center space-x-3">
            <button
              @click="closeQrModal"
              class="px-4 py-2 text-sm font-medium text-slate-700 bg-slate-100 rounded-md hover:bg-slate-200"
            >
              Cancelar
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.modal {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background: rgba(0,0,0,0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.modal-content {
  background: #fff;
  padding: 2rem;
  border-radius: 8px;
  text-align: center;
}
</style> 