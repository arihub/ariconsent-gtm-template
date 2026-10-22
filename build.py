#!/usr/bin/env python3
"""Builds template.tpl from src/template.js, the parameters, permissions and tests below.

Run: python3 build.py   (writes template.tpl next to this file)
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent

TERMS = """___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.
"""

INFO = {
    "type": "TAG",
    "id": "cvt_temp_public_id",
    "version": 1,
    "securityGroups": [],
    "displayName": "AriConsent – Consent Mode",
    "categories": ["TAG_MANAGEMENT", "UTILITY"],
    "brand": {"id": "brand_dummy", "displayName": "AriHub"},
    "description": "Sets Google Consent Mode v2 defaults (per region if you like) and applies each visitor's choice from the AriConsent cookie banner for WordPress. Fire on Consent Initialization – All Pages.",
    "containerContexts": ["WEB"],
}

DEFAULT_DENIED = "ad_storage,ad_user_data,ad_personalization,analytics_storage,personalization_storage"

PARAMETERS = [
    {
        "type": "PARAM_TABLE",
        "name": "defaultSettings",
        "displayName": "Default settings",
        "help": "Consent state before the visitor chooses. One row per region; leave Region empty for everyone else. Region uses ISO 3166-2 codes such as NO, SE, US-CA (comma-separated). Consent types: ad_storage, ad_user_data, ad_personalization, analytics_storage, functionality_storage, personalization_storage, security_storage.",
        "paramTableColumns": [
            {"param": {"type": "TEXT", "name": "region", "displayName": "Region (empty = all others)", "simpleValueType": True}, "isUnique": True},
            {"param": {"type": "TEXT", "name": "granted", "displayName": "Granted consent types (comma-separated)", "simpleValueType": True}, "isUnique": False},
            {"param": {"type": "TEXT", "name": "denied", "displayName": "Denied consent types (comma-separated)", "simpleValueType": True}, "isUnique": False},
        ],
        "newRowButtonText": "Add region",
        "defaultValue": [
            {"region": "", "granted": "functionality_storage,security_storage", "denied": DEFAULT_DENIED}
        ],
    },
    {
        "type": "TEXT",
        "name": "wait_for_update",
        "displayName": "Wait for update (milliseconds)",
        "simpleValueType": True,
        "defaultValue": "500",
        "help": "How long Google tags wait for the visitor's stored choice before using the defaults. 500 is a good value.",
        "valueValidators": [{"type": "NON_NEGATIVE_NUMBER"}],
    },
    {
        "type": "CHECKBOX",
        "name": "ads_data_redaction",
        "checkboxText": "Redact ads data when ad_storage is denied",
        "simpleValueType": True,
        "defaultValue": True,
    },
    {
        "type": "CHECKBOX",
        "name": "url_passthrough",
        "checkboxText": "Pass ad click information through URLs",
        "simpleValueType": True,
        "defaultValue": False,
    },
]

CONSENT_TYPES = [
    "ad_storage", "ad_user_data", "ad_personalization", "analytics_storage",
    "functionality_storage", "personalization_storage", "security_storage",
]


def string(v):
    return {"type": 1, "string": v}


def boolean(v):
    return {"type": 8, "boolean": v}


def map_item(keys, values):
    return {"type": 3, "mapKey": [string(k) for k in keys], "mapValue": values}


def permission(public_id, params):
    return {
        "instance": {"key": {"publicId": public_id, "versionId": "1"}, "param": params},
        "clientAnnotations": {"isEditedByUser": True},
        "isRequired": True,
    }


PERMISSIONS = [
    permission("access_consent", [{
        "key": "consentTypes",
        "value": {"type": 2, "listItem": [
            map_item(["consentType", "read", "write"], [string(t), boolean(False), boolean(True)])
            for t in CONSENT_TYPES
        ]},
    }]),
    permission("write_data_layer", [{
        "key": "keyPatterns",
        "value": {"type": 2, "listItem": [string("ads_data_redaction"), string("url_passthrough")]},
    }]),
    permission("access_globals", [{
        "key": "keys",
        "value": {"type": 2, "listItem": [
            map_item(["key", "read", "write", "execute"], [string("ariconsentGcm.subscribe"), boolean(True), boolean(False), boolean(True)]),
            map_item(["key", "read", "write", "execute"], [string("ariconsentGcmCallback"), boolean(True), boolean(True), boolean(False)]),
        ]},
    }]),
]

TESTS = r"""scenarios:
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
"""

NOTES = "Source and issues: https://github.com/arihub/ariconsent-gtm-template\n"


def build():
    code = (ROOT / "src" / "template.js").read_text(encoding="utf-8")
    parts = [
        TERMS,
        "\n___INFO___\n\n" + json.dumps(INFO, indent=2, ensure_ascii=False) + "\n",
        "\n___TEMPLATE_PARAMETERS___\n\n" + json.dumps(PARAMETERS, indent=2, ensure_ascii=False) + "\n",
        "\n___SANDBOXED_JS_FOR_WEB_TEMPLATE___\n\n" + code.rstrip("\n") + "\n",
        "\n___WEB_PERMISSIONS___\n\n" + json.dumps(PERMISSIONS, indent=2, ensure_ascii=False) + "\n",
        "\n___TESTS___\n\n" + TESTS,
        "\n___NOTES___\n\n" + NOTES,
    ]
    (ROOT / "template.tpl").write_text("".join(parts), encoding="utf-8")


if __name__ == "__main__":
    build()
