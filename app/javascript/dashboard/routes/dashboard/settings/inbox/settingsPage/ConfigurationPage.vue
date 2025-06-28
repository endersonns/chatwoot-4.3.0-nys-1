<script>
import { useAlert } from 'dashboard/composables';
import { useInbox } from 'dashboard/composables/useInbox';
import inboxMixin from 'shared/mixins/inboxMixin';
import SettingsSection from '../../../../../components/SettingsSection.vue';
import ImapSettings from '../ImapSettings.vue';
import SmtpSettings from '../SmtpSettings.vue';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    SettingsSection,
    ImapSettings,
    SmtpSettings,
    NextButton,
  },
  mixins: [inboxMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  setup() {
    const { v$ } = useVuelidate();
    const { isAEvolutionApiChannel } = useInbox();
    return { v$, isAEvolutionApiChannel };
  },
  data() {
    return {
      hmacMandatory: false,
      whatsAppInboxAPIKey: '',
      isLoggingOut: false,
    };
  },
  validations: {
    whatsAppInboxAPIKey: { required },
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      this.hmacMandatory = this.inbox.hmac_mandatory || false;
    },
    handleHmacFlag() {
      this.updateInbox();
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            hmac_mandatory: this.hmacMandatory,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async updateWhatsAppInboxAPIKey() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {},
        };

        payload.channel.provider_config = {
          ...this.inbox.provider_config,
          api_key: this.whatsAppInboxAPIKey,
        };

        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async logoutEvolutionInstance() {
      try {
        this.isLoggingOut = true;
        const instanceId = this.inbox.provider_config?.instance_id;
        if (!instanceId) {
          throw new Error('ID da instância não encontrado');
        }
        
        await this.$store.dispatch('inboxes/logoutEvolutionInstance', {
          instance_id: instanceId,
        });
        
        // Limpar provider_config após logout
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            provider_config: {
              ...this.inbox.provider_config,
              instance_id: null,
              connected: false,
            },
          },
        };
        
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(error.message || this.$t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.ERROR_MESSAGE'));
      } finally {
        this.isLoggingOut = false;
      }
    },
  },
};
</script>

<template>
  <div v-if="isATwilioChannel" class="mx-8">
    <SettingsSection
      :title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.TITLE')"
      :sub-title="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE')"
    >
      <woot-code :script="inbox.callback_webhook_url" lang="html" />
    </SettingsSection>
  </div>
  <div v-else-if="isALineChannel" class="mx-8">
    <SettingsSection
      :title="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.TITLE')"
      :sub-title="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE')"
    >
      <woot-code :script="inbox.callback_webhook_url" lang="html" />
    </SettingsSection>
  </div>
  <div v-else-if="isAWebWidgetInbox">
    <div class="mx-8">
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_HEADING')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.MESSENGER_SUB_HEAD')"
      >
        <woot-code
          :script="inbox.web_widget_script"
          lang="html"
          :codepen-title="`${inbox.name} - Chatwoot Widget Test`"
          enable-code-pen
        />
      </SettingsSection>

      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_VERIFICATION')"
      >
        <woot-code :script="inbox.hmac_token" />
        <template #subTitle>
          {{ $t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION') }}
          <a
            target="_blank"
            rel="noopener noreferrer"
            href="https://www.chatwoot.com/docs/product/channels/live-chat/sdk/identity-validation/"
          >
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.HMAC_LINK_TO_DOCS') }}
          </a>
        </template>
      </SettingsSection>
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_VERIFICATION')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_DESCRIPTION')"
      >
        <div class="flex items-center gap-2">
          <input
            id="hmacMandatory"
            v-model="hmacMandatory"
            type="checkbox"
            @change="handleHmacFlag"
          />
          <label for="hmacMandatory">
            {{ $t('INBOX_MGMT.EDIT.ENABLE_HMAC.LABEL') }}
          </label>
        </div>
      </SettingsSection>
    </div>
  </div>
  <div v-else-if="isAPIInbox" class="mx-8">
    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER_SUB_TEXT')"
    >
      <woot-code :script="inbox.inbox_identifier" />
    </SettingsSection>

    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_VERIFICATION')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION')"
    >
      <woot-code :script="inbox.hmac_token" />
    </SettingsSection>
    <SettingsSection
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_VERIFICATION')"
      :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_DESCRIPTION')"
    >
      <div class="flex items-center gap-2">
        <input
          id="hmacMandatory"
          v-model="hmacMandatory"
          type="checkbox"
          @change="handleHmacFlag"
        />
        <label for="hmacMandatory">
          {{ $t('INBOX_MGMT.EDIT.ENABLE_HMAC.LABEL') }}
        </label>
      </div>
    </SettingsSection>
  </div>
  <div v-else-if="isAnEmailChannel">
    <div class="mx-8">
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.FORWARD_EMAIL_SUB_TEXT')"
      >
        <woot-code :script="inbox.forward_to_email" />
      </SettingsSection>
    </div>
    <ImapSettings :inbox="inbox" />
    <SmtpSettings v-if="inbox.imap_enabled" :inbox="inbox" />
  </div>
  <div v-else-if="isAWhatsAppChannel && !isATwilioChannel">
    <div v-if="inbox.provider_config" class="mx-8">
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_SUBHEADER')"
      >
        <woot-code :script="inbox.provider_config.webhook_verify_token" />
      </SettingsSection>
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_TITLE')"
        :sub-title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_SUBHEADER')"
      >
        <woot-code :script="inbox.provider_config.api_key" />
      </SettingsSection>
      <SettingsSection
        :title="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_TITLE')"
        :sub-title="
          $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_SUBHEADER')
        "
      >
        <div
          class="flex items-center justify-between flex-1 mt-2 whatsapp-settings--content"
        >
          <woot-input
            v-model="whatsAppInboxAPIKey"
            type="text"
            class="flex-1 mr-2"
            :placeholder="
              $t(
                'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_PLACEHOLDER'
              )
            "
          />
          <NextButton
            :disabled="v$.whatsAppInboxAPIKey.$invalid"
            @click="updateWhatsAppInboxAPIKey"
          >
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON') }}
          </NextButton>
        </div>
      </SettingsSection>
    </div>
  </div>
  <div v-else-if="isAEvolutionApiChannel">
    <div v-if="inbox.provider_config" class="mx-8">
      <SettingsSection
        :title="$t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.TITLE')"
        :sub-title="$t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.SUBTITLE')"
      >
        <div class="space-y-4">
          <div class="flex items-center justify-between p-4 bg-slate-50 rounded-lg">
            <div>
              <p class="text-sm font-medium text-slate-700">{{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.INSTANCE_ID') }}</p>
              <p class="text-sm text-slate-600">{{ inbox.provider_config.instance_id || $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.NOT_AVAILABLE') }}</p>
            </div>
            <div class="flex items-center">
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                {{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.STATUS_CONNECTED') }}
              </span>
            </div>
          </div>
          
          <div class="flex items-center justify-between p-4 bg-slate-50 rounded-lg">
            <div>
              <p class="text-sm font-medium text-slate-700">{{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.PHONE_NUMBER') }}</p>
              <p class="text-sm text-slate-600">{{ inbox.phone_number || $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.NOT_AVAILABLE') }}</p>
            </div>
          </div>
          
          <div class="border-t pt-4">
            <p class="text-sm text-slate-600 mb-4">
              {{ $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.DISCONNECT_WARNING') }}
            </p>
            <NextButton
              type="button"
              :loading="isLoggingOut"
              :disabled="isLoggingOut"
              ruby
              @click="logoutEvolutionInstance"
            >
              {{ isLoggingOut ? $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.DISCONNECTING') : $t('INBOX_MGMT.ADD.WHATSAPP.EVOLUTION_API.INSTANCE_INFO.DISCONNECT_BUTTON') }}
            </NextButton>
          </div>
        </div>
      </SettingsSection>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.whatsapp-settings--content {
  ::v-deep input {
    margin-bottom: 0;
  }
}
</style>
