// Runs the template's sandboxed code in Node with stand-ins for the Tag Manager APIs, and then the
// real AriConsent bridge from the WordPress plugin, to check the two work together.
// This checks the logic only; Tag Manager's own sandbox rules are checked by its template editor tests.
// Run: node tests/sandbox.test.js [path to the AriConsent bridge script]
'use strict';
const fs = require('fs');
const path = require('path');
const assert = require('assert');

const tpl = fs.readFileSync(path.join(__dirname, '..', 'template.tpl'), 'utf8');
const code = tpl.split('___SANDBOXED_JS_FOR_WEB_TEMPLATE___')[1].split('___WEB_PERMISSIONS___')[0];

function getType(v) {
	if (v === null) return 'null';
	if (Array.isArray(v)) return 'array';
	return typeof v;
}

function run(data, win) {
	const calls = { defaults: [], updates: [], set: [], success: 0 };
	const api = {
		setDefaultConsentState: (c) => calls.defaults.push(c),
		updateConsentState: (c) => calls.updates.push(c),
		gtagSet: (o) => calls.set.push(o),
		copyFromWindow: (key) => key.split('.').reduce((o, k) => (o == null ? undefined : o[k]), win),
		callInWindow: (p, ...args) => {
			const parts = p.split('.');
			const fn = parts.reduce((o, k) => (o == null ? undefined : o[k]), win);
			return fn.apply(parts.length > 1 ? win[parts[0]] : win, args);
		},
		setInWindow: (key, value) => { win[key] = value; },
		makeInteger: (v) => parseInt(v, 10),
		getType,
	};
	data.gtmOnSuccess = () => calls.success++;
	new Function('require', 'data', code)((name) => api[name], data);
	return calls;
}

const base = () => ({
	defaultSettings: [{ region: '', granted: 'functionality_storage,security_storage', denied: 'ad_storage,ad_user_data,ad_personalization,analytics_storage,personalization_storage' }],
	wait_for_update: '500',
	ads_data_redaction: true,
	url_passthrough: false,
});

let passed = 0;
function check(name, fn) {
	fn();
	passed++;
	console.log('PASS', name);
}

check('defaults for everyone, redaction on, success reported', () => {
	const c = run(base(), {});
	assert.deepStrictEqual(c.defaults, [{ functionality_storage: 'granted', security_storage: 'granted', ad_storage: 'denied', ad_user_data: 'denied', ad_personalization: 'denied', analytics_storage: 'denied', personalization_storage: 'denied', wait_for_update: 500 }]);
	assert.deepStrictEqual(c.set, [{ ads_data_redaction: true, url_passthrough: false }]);
	assert.strictEqual(c.success, 1);
});

check('regions trimmed, unknown types dropped, bad wait falls back to 500', () => {
	const d = base();
	d.defaultSettings = [{ region: ' NO , SE ', granted: 'security_storage', denied: 'ad_storage, made_up' }, { region: '', granted: 'ad_storage', denied: '' }];
	d.wait_for_update = 'abc';
	const c = run(d, {});
	assert.deepStrictEqual(c.defaults[0], { security_storage: 'granted', ad_storage: 'denied', region: ['NO', 'SE'], wait_for_update: 500 });
	assert.deepStrictEqual(c.defaults[1], { ad_storage: 'granted', wait_for_update: 500 });
});

check('wait_for_update of exactly 0 is kept', () => {
	const d = base();
	d.wait_for_update = '0';
	assert.strictEqual(run(d, {}).defaults[0].wait_for_update, 0);
});

const bridgeFile = process.argv[2];
if (bridgeFile) {
	const bridge = fs.readFileSync(bridgeFile, 'utf8');
	const runBridge = (win, cookie) => new Function('window', 'document', bridge)(win, { cookie });
	const choice = (c, s) => 'ariconsent=' + encodeURIComponent(JSON.stringify(Object.assign({ r: 1, id: 'x', t: 1, c }, s ? { s } : {})));

	check('bridge first: stored choice applied as soon as the template subscribes', () => {
		const win = {};
		runBridge(win, choice({ preferences: false, statistics: true, marketing: false }));
		const c = run(base(), win);
		assert.deepStrictEqual(c.updates, [{ ad_storage: 'denied', ad_user_data: 'denied', ad_personalization: 'denied', analytics_storage: 'granted', functionality_storage: 'granted', personalization_storage: 'denied', security_storage: 'granted' }]);
	});

	check('template first: callback left in window and picked up by the bridge', () => {
		const win = {};
		const c = run(base(), win);
		assert.strictEqual(typeof win.ariconsentGcmCallback, 'function');
		runBridge(win, choice({ preferences: true, statistics: true, marketing: true }));
		assert.strictEqual(c.updates.length, 1);
		assert.strictEqual(c.updates[0].ad_storage, 'granted');
	});

	check('a choice for an older policy revision is not applied', () => {
		const win = {};
		runBridge(win, 'ariconsent=' + encodeURIComponent(JSON.stringify({ r: 0, c: { marketing: true } })));
		const c = run(base(), win);
		assert.deepStrictEqual(c.updates, []);
	});

	check('no choice yet: nothing applied until the visitor chooses, then publish reaches the template', () => {
		const win = {};
		runBridge(win, '');
		const c = run(base(), win);
		assert.deepStrictEqual(c.updates, []);
		win.ariconsentGcm.publish({ ad_storage: 'granted', ad_user_data: 'granted', ad_personalization: 'granted', analytics_storage: 'denied', personalization_storage: 'denied', functionality_storage: 'granted', security_storage: 'granted' });
		assert.strictEqual(c.updates.length, 1);
		assert.strictEqual(c.updates[0].analytics_storage, 'denied');
	});

	check('turning Google Analytics off in single-service mode denies analytics_storage', () => {
		const win = {};
		runBridge(win, choice({ preferences: false, statistics: true, marketing: false }, ['google-analytics']));
		const c = run(base(), win);
		assert.strictEqual(c.updates[0].analytics_storage, 'denied');
	});
}

console.log('\n' + passed + ' passed');
