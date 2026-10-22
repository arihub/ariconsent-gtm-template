___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.

___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "AriConsent – Consent Mode",
  "categories": [
    "TAG_MANAGEMENT",
    "UTILITY"
  ],
  "brand": {
    "id": "brand_dummy",
    "displayName": "AriHub"
  },
  "description": "Sets Google Consent Mode v2 defaults (per region if you like) and applies each visitor's choice from the AriConsent cookie banner for WordPress. Fire on Consent Initialization – All Pages.",
  "containerContexts": [
    "WEB"
  ]
}

___TEMPLATE_PARAMETERS___

[
  {
    "type": "PARAM_TABLE",
    "name": "defaultSettings",
    "displayName": "Default settings",
    "help": "Consent state before the visitor chooses. One row per region; leave Region empty for everyone else. Region uses ISO 3166-2 codes such as NO, SE, US-CA (comma-separated). Consent types: ad_storage, ad_user_data, ad_personalization, analytics_storage, functionality_storage, personalization_storage, security_storage.",
    "paramTableColumns": [
      {
        "param": {
          "type": "TEXT",
          "name": "region",
          "displayName": "Region (empty = all others)",
          "simpleValueType": true
        },
        "isUnique": true
      },
      {
        "param": {
          "type": "TEXT",
          "name": "granted",
          "displayName": "Granted consent types (comma-separated)",
          "simpleValueType": true
        },
        "isUnique": false
      },
      {
        "param": {
          "type": "TEXT",
          "name": "denied",
          "displayName": "Denied consent types (comma-separated)",
          "simpleValueType": true
        },
        "isUnique": false
      }
    ],
    "newRowButtonText": "Add region",
    "defaultValue": [
      {
        "region": "",
        "granted": "functionality_storage,security_storage",
        "denied": "ad_storage,ad_user_data,ad_personalization,analytics_storage,personalization_storage"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "wait_for_update",
    "displayName": "Wait for update (milliseconds)",
    "simpleValueType": true,
    "defaultValue": "500",
    "help": "How long Google tags wait for the visitor's stored choice before using the defaults. 500 is a good value.",
    "valueValidators": [
      {
        "type": "NON_NEGATIVE_NUMBER"
      }
    ]
  },
  {
    "type": "CHECKBOX",
    "name": "ads_data_redaction",
    "checkboxText": "Redact ads data when ad_storage is denied",
    "simpleValueType": true,
    "defaultValue": true
  },
  {
    "type": "CHECKBOX",
    "name": "url_passthrough",
    "checkboxText": "Pass ad click information through URLs",
    "simpleValueType": true,
    "defaultValue": false
  }
]

___SANDBOXED_JS_FOR_WEB_TEMPLATE___

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

___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "access_consent",
        "versionId": "1"
      },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_storage"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_user_data"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_personalization"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "analytics_storage"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "functionality_storage"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "personalization_storage"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "security_storage"
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "write_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 1,
                "string": "ads_data_redaction"
              },
              {
                "type": 1,
                "string": "url_passthrough"
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ariconsentGcm.subscribe"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ariconsentGcmCallback"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]

___TESTS___

scenarios:
- name: Sets EU-style defaults for everyone
  code: |-
    runCode(mockData);
    assertApi('setDefaultConsentState').wasCalledWith({
      functionality_storage: 'granted',
      security_storage: 'granted',
      ad_storage: 'denied',
      ad_user_data: 'denied',
      ad_personalization: 'denied',
      analytics_storage: 'denied',
      personalization_storage: 'denied',
      wait_for_update: 500
    });
    assertApi('gtagSet').wasCalledWith({ads_data_redaction: true, url_passthrough: false});
    assertApi('gtmOnSuccess').wasCalled();
- name: One default per region, region codes trimmed, unknown types ignored
  code: |-
    mockData.defaultSettings = [
      {region: 'NO, SE', granted: 'security_storage', denied: 'ad_storage,analytics_storage,made_up'},
      {region: '', granted: 'ad_storage,analytics_storage', denied: ''}
    ];
    mockData.wait_for_update = '800';
    runCode(mockData);
    assertApi('setDefaultConsentState').wasCalledWith({security_storage: 'granted', ad_storage: 'denied', analytics_storage: 'denied', region: ['NO', 'SE'], wait_for_update: 800});
    assertApi('setDefaultConsentState').wasCalledWith({ad_storage: 'granted', analytics_storage: 'granted', wait_for_update: 800});
- name: Subscribes to AriConsent when the bridge is on the page
  code: |-
    let subscribed;
    mock('copyFromWindow', (key) => key === 'ariconsentGcm.subscribe' ? (cb) => {} : undefined);
    mock('callInWindow', (path, cb) => { subscribed = cb; });
    runCode(mockData);
    assertThat(typeof subscribed).isEqualTo('function');
    subscribed({ad_storage: 'granted', analytics_storage: 'denied', made_up: 'granted', ad_user_data: 'maybe'});
    assertApi('updateConsentState').wasCalledWith({ad_storage: 'granted', analytics_storage: 'denied'});
    assertApi('setInWindow').wasNotCalled();
- name: Leaves its callback for AriConsent when the bridge loads later
  code: |-
    mock('copyFromWindow', (key) => undefined);
    runCode(mockData);
    assertApi('setInWindow').wasCalled();
    assertApi('callInWindow').wasNotCalled();
setup: |-
  const mockData = {
    defaultSettings: [{region: '', granted: 'functionality_storage,security_storage', denied: 'ad_storage,ad_user_data,ad_personalization,analytics_storage,personalization_storage'}],
    wait_for_update: '500',
    ads_data_redaction: true,
    url_passthrough: false
  };

___NOTES___

Source and issues: https://github.com/arihub/ariconsent-gtm-template
