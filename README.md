# AriConsent – Consent Mode (Google Tag Manager template)

Sets Google Consent Mode v2 defaults in Google Tag Manager and applies each visitor's choice from
[AriConsent](https://www.arihub.com/ariconsent/), the cookie banner for WordPress made by AriHub in Norway.

## Setup

1. In WordPress, install AriConsent (version 0.5 or later).
2. In Tag Manager, add **AriConsent – Consent Mode** from the Community Template Gallery and create a tag with it.
3. Fire the tag on **Consent Initialization – All Pages**.
4. Adjust the default settings if you need to. The default denies everything except `functionality_storage` and `security_storage`, for every region. Add rows to use different defaults per region (ISO 3166-2 codes such as `NO`, `SE` or `US-CA`).
5. Publish the container.
6. In WordPress, go to **AriConsent → Google & Microsoft** and turn on **Tag Manager sets the defaults with the AriConsent template**. AriConsent then stops setting defaults itself and passes each visitor's choice to this tag.

## How it works

- On Consent Initialization the tag calls `setDefaultConsentState` for each row, with `wait_for_update` (500 ms by default), and sets `ads_data_redaction` and `url_passthrough` as chosen.
- AriConsent prints a small script, `window.ariconsentGcm`, carrying the visitor's stored choice as the seven Google consent types. The tag subscribes to it and applies the choice with `updateConsentState`, both straight away and whenever the visitor changes it.
- If the tag runs before AriConsent's script, it leaves its callback in `window.ariconsentGcmCallback`, and AriConsent picks it up.
- AriConsent's categories map to Google consent types as follows:
  - Statistics → `analytics_storage`
  - Marketing → `ad_storage`, `ad_user_data`, `ad_personalization`
  - Preferences → `personalization_storage`
  - `functionality_storage` and `security_storage` are always granted.
  - When visitors may switch single services, turning off a Google service in a category denies that category's Google types.

## Development

`template.tpl` is built from `src/template.js` by `python3 build.py`. `node tests/sandbox.test.js` runs the sandboxed code with stand-ins for the Tag Manager APIs. Given the path to AriConsent's bridge script, it also runs the code against that script. The template's own tests (`___TESTS___`) run in the Tag Manager template editor.

## Support

Report problems in this repository's issues, or write to support@arihub.com.

## Licence

Apache License 2.0. See `LICENSE`.
