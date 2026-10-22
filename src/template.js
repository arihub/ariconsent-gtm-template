// AriConsent – Consent Mode. Sandboxed JavaScript for the Google Tag Manager template.
// Fire on "Consent Initialization – All Pages".
const setDefaultConsentState = require('setDefaultConsentState');
const updateConsentState = require('updateConsentState');
const gtagSet = require('gtagSet');
const copyFromWindow = require('copyFromWindow');
const callInWindow = require('callInWindow');
const setInWindow = require('setInWindow');
const makeInteger = require('makeInteger');
const getType = require('getType');

const CONSENT_TYPES = [
  'ad_storage',
  'ad_user_data',
  'ad_personalization',
  'analytics_storage',
  'functionality_storage',
  'personalization_storage',
  'security_storage'
];

// Comma-separated list from a table cell, trimmed, empty entries dropped.
const splitInput = (input) => {
  if (getType(input) !== 'string') {
    return [];
  }
  return input.split(',')
    .map((entry) => entry.trim())
    .filter((entry) => entry.length !== 0);
};

// Only the seven Google consent types, only 'granted' or 'denied'.
const cleanState = (state) => {
  const out = {};
  if (getType(state) !== 'object') {
    return out;
  }
  CONSENT_TYPES.forEach((type) => {
    if (state[type] === 'granted' || state[type] === 'denied') {
      out[type] = state[type];
    }
  });
  return out;
};

// Applies a choice AriConsent publishes: Google consent types mapped from the visitor's categories.
const onUserConsent = (state) => {
  const update = cleanState(state);
  if (getType(update.ad_storage) !== 'undefined' || getType(update.analytics_storage) !== 'undefined' || getType(update.personalization_storage) !== 'undefined') {
    updateConsentState(update);
  }
};

gtagSet({
  ads_data_redaction: data.ads_data_redaction === true,
  url_passthrough: data.url_passthrough === true
});

let wait = makeInteger(data.wait_for_update);
if (getType(wait) !== 'number' || !(wait >= 0)) { // Also catches NaN.
  wait = 500;
}

const rows = getType(data.defaultSettings) === 'array' ? data.defaultSettings : [];
rows.forEach((row) => {
  const command = {};
  splitInput(row.granted).forEach((type) => {
    if (CONSENT_TYPES.indexOf(type) !== -1) {
      command[type] = 'granted';
    }
  });
  splitInput(row.denied).forEach((type) => {
    if (CONSENT_TYPES.indexOf(type) !== -1) {
      command[type] = 'denied';
    }
  });
  const regions = splitInput(row.region);
  if (regions.length !== 0) {
    command.region = regions;
  }
  command.wait_for_update = wait;
  setDefaultConsentState(command);
});

// AriConsent's bridge (printed by the WordPress plugin) applies the stored choice at once when we
// subscribe, and every later choice. If the bridge has not loaded yet, leave the callback where the
// bridge picks it up.
if (getType(copyFromWindow('ariconsentGcm.subscribe')) === 'function') {
  callInWindow('ariconsentGcm.subscribe', onUserConsent);
} else {
  setInWindow('ariconsentGcmCallback', onUserConsent, true);
}

data.gtmOnSuccess();
