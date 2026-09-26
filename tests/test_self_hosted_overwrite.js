#!/usr/bin/env node
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');

const source = fs.readFileSync('overwrite_script.js', 'utf8') + '\n;globalThis.__myRulesMain = main;';
const context = { console };
vm.createContext(context);
vm.runInContext(source, context);
const main = context.__myRulesMain;

function groupMap(config) {
  return new Map(config['proxy-groups'].map(group => [group.name, group]));
}

const selfNodes = [
  'DMIT | LAX-01 | Snell',
  'DMIT | LAX-01 | HY2',
  'DMIT | LAX-02 | Snell',
  'DMIT | LAX-02 | HY2',
  'Lisa | LAX-01 | Snell',
  'Lisa | LAX-01 | HY2',
];

const config = {
  proxies: [
    ...selfNodes.map((name, i) => ({ name, type: i % 2 === 0 ? 'snell' : 'hysteria2' })),
    { name: '🇭🇰 HK | 香港 01', type: 'ss' },
    { name: '🇭🇰 HK | 香港 02', type: 'ss' },
    { name: '🇺🇸 US | 美国 01', type: 'ss' },
    { name: '🇺🇸 US | 美国 02', type: 'ss' },
    { name: '🇯🇵 JP | 日本 01', type: 'ss' },
  ],
};

const out = main(JSON.parse(JSON.stringify(config)));
const groups = groupMap(out);

assert.strictEqual(groups.get('Proxies').proxies[0], '🏠 自建节点');
assert.strictEqual(groups.get('AI').proxies[0], '🏠 自建节点');

assert.deepStrictEqual(
  Array.from(groups.get('🏠 自建节点').proxies),
  ['🏠 自建节点-自动', '🖥 DMIT · LAX-01', '🖥 DMIT · LAX-02', '🖥 Lisa · LAX-01']
);
assert.deepStrictEqual(Array.from(groups.get('🏠 自建节点-自动').proxies), selfNodes);

assert.deepStrictEqual(
  Array.from(groups.get('🖥 DMIT · LAX-01').proxies),
  ['🖥 DMIT · LAX-01-自动', 'DMIT | LAX-01 | Snell', 'DMIT | LAX-01 | HY2']
);
assert.deepStrictEqual(
  Array.from(groups.get('🖥 DMIT · LAX-01-自动').proxies),
  ['DMIT | LAX-01 | Snell', 'DMIT | LAX-01 | HY2']
);

for (const name of selfNodes) {
  assert.ok(!groups.get('🇺🇸 美国').proxies.includes(name), `${name} leaked into US group`);
  assert.ok(!groups.get('🌍 其他地区').proxies.includes(name), `${name} leaked into Other group`);
}

assert.ok(groups.get('🌍 其他地区').proxies.includes('🇯🇵 JP | 日本 01'));

const visibleOrder = Array.from(out['proxy-groups'], group => group.name);
const finalIndex = visibleOrder.indexOf('✈️Final');
assert.deepStrictEqual(
  visibleOrder.slice(finalIndex + 1, finalIndex + 9),
  [
    '🏠 自建节点',
    '🏠 自建节点-自动',
    '🖥 DMIT · LAX-01',
    '🖥 DMIT · LAX-01-自动',
    '🖥 DMIT · LAX-02',
    '🖥 DMIT · LAX-02-自动',
    '🖥 Lisa · LAX-01',
    '🖥 Lisa · LAX-01-自动',
  ]
);

// No self-hosted nodes: old behavior remains, no empty self groups.
const noSelf = main({
  proxies: [
    { name: '🇭🇰 HK | 香港 01', type: 'ss' },
    { name: '🇭🇰 HK | 香港 02', type: 'ss' },
  ],
});
const noSelfNames = noSelf['proxy-groups'].map(group => group.name);
assert.ok(!noSelfNames.includes('🏠 自建节点'));
assert.strictEqual(noSelf['proxy-groups'][0].proxies[0], '🇭🇰 香港');

console.log('test_self_hosted_overwrite.js: PASS');
