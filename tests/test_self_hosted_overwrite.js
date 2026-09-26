#!/usr/bin/env node
const fs = require('fs');
const vm = require('vm');
const path = require('path');

const source = fs.readFileSync(path.join(__dirname, '..', 'overwrite_script.js'), 'utf8');
const sandbox = {};
vm.createContext(sandbox);
vm.runInContext(source, sandbox);

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

const config = {
  proxies: [
    { name: 'DMIT | LAX | Snell', type: 'snell' },
    { name: 'DMIT | LAX | HY2', type: 'hysteria2' },
    { name: '🇺🇸 US | 美国 01', type: 'ss' },
    { name: '🇺🇸 US | 美国 02', type: 'ss' },
    { name: '🇭🇰 HK | 香港 01', type: 'ss' },
    { name: '🇭🇰 HK | 香港 02', type: 'ss' },
    { name: '🇯🇵 JP | 日本 01', type: 'ss' },
  ],
};

const result = sandbox.main(config);
const groups = new Map(result['proxy-groups'].map(g => [g.name, g]));

assert(groups.has('🛠 DMIT自建'), 'missing DMIT self-hosted selector');
assert(groups.has('🛠 DMIT自建-自动'), 'missing DMIT auto group');
assert(groups.get('Proxies').proxies[0] === '🛠 DMIT自建', 'DMIT should be first in Proxies');
assert(groups.get('AI').proxies[0] === '🛠 DMIT自建', 'DMIT should be first in AI');
assert(
  JSON.stringify(groups.get('🛠 DMIT自建').proxies) ===
    JSON.stringify(['🛠 DMIT自建-自动', 'DMIT | LAX | Snell', 'DMIT | LAX | HY2']),
  'unexpected DMIT selector members'
);
assert(!groups.get('🇺🇸 美国').proxies.includes('DMIT | LAX | Snell'), 'DMIT leaked into US group');
assert(!groups.get('🌍 其他地区').proxies.includes('DMIT | LAX | Snell'), 'DMIT leaked into Other group');

console.log('self-hosted overwrite tests passed');
