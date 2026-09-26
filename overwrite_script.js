// ============================================================
// my-rulesets 覆写脚本（FlClash / Clash Verge Rev / Mihomo）
// ------------------------------------------------------------
// 前端可见策略（Self-hosted V2）：
//   Proxies / 应用组 / Direct / Final
//   🏠 自建节点
//   🏠 自建节点-自动
//   🖥 <Provider> · <Machine-ID>
//   🖥 <Provider> · <Machine-ID>-自动
//   国家分组 + 各 -自动
//
// 自建节点命名：<Provider> | <Machine-ID> | <Protocol>
// 例：DMIT | LAX-01 | Snell、Lisa | LAX-01 | HY2
// Provider / Machine-ID 只允许 ASCII 字母数字 . _ -；Protocol 必须在支持清单中。
// 自建节点不参与国家归类，也不会进入「🌍 其他地区」。
// 顶层/机器自动组都直接测试真实协议节点，不嵌套自动组。
// ============================================================
function main(config, profileName) {
  const nodes = config.proxies || [];

  const PSEUDO_NODE_RE = /Traffic|Expire|流量|到期|剩余|套餐|官网|订阅|^Panel|^www\.|creamdata\.xyz|节点|主页/i;
  const SELF_ID_RE = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;
  const SELF_PROTOCOL_RE = /^(?:ss|ssr|trojan|anytls|vmess|vless|hysteria2|hysteria|hy2|tuic|wireguard|snell|http|socks5)(?:\s|$)/i;
  const SELF_GROUP = '🏠 自建节点';
  const SELF_AUTO = '🏠 自建节点-自动';
  const TEST_URL = 'http://www.gstatic.com/generate_204';

  const countryPatterns = {
    '🇭🇰 香港': /香港|🇭🇰|(?:^|[^A-Za-z])HK(?:[^A-Za-z]|$)|Hong\s?Kong/i,
    '🇸🇬 新加坡': /新加坡|🇸🇬|(?:^|[^A-Za-z])SG(?:[^A-Za-z]|$)|Singapore/i,
    '🇯🇵 日本': /日本|🇯🇵|(?:^|[^A-Za-z])JP(?:[^A-Za-z]|$)|Japan/i,
    '🇺🇸 美国': /美国|🇺🇸|🇺🇲|(?:^|[^A-Za-z])US(?:[^A-Za-z]|$)|America/i,
    '🇨🇳 台湾': /台湾|🇨🇳|🇹🇼|(?:^|[^A-Za-z])TW(?:[^A-Za-z]|$)|Taiwan/i,
    '🇰🇷 韩国': /韩国|🇰🇷|(?:^|[^A-Za-z])KR(?:[^A-Za-z]|$)|Korea/i,
    '🇬🇧 英国': /英国|🇬🇧|(?:^|[^A-Za-z])(?:UK|GB)(?:[^A-Za-z]|$)|United\s?Kingdom/i,
    '🇩🇪 德国': /德国|🇩🇪|(?:^|[^A-Za-z])DE(?:[^A-Za-z]|$)|Germany/i,
    '🇦🇺 澳大利亚': /澳大利亚|澳洲|🇦🇺|(?:^|[^A-Za-z])AU(?:[^A-Za-z]|$)|Australia/i,
    '🇨🇦 加拿大': /加拿大|🇨🇦|(?:^|[^A-Za-z])CA(?:[^A-Za-z]|$)|Canada/i,
    '🇫🇷 法国': /法国|🇫🇷|(?:^|[^A-Za-z])FR(?:[^A-Za-z]|$)|France/i,
    '🇷🇺 俄罗斯': /俄罗斯|🇷🇺|(?:^|[^A-Za-z])RU(?:[^A-Za-z]|$)|Russia/i,
    '🇳🇱 荷兰': /荷兰|🇳🇱|(?:^|[^A-Za-z])NL(?:[^A-Za-z]|$)|Netherlands/i,
    '🇮🇳 印度': /印度|🇮🇳|(?:^|[^A-Za-z])IN(?:[^A-Za-z]|$)|India/i,
    '🇹🇷 土耳其': /土耳其|🇹🇷|(?:^|[^A-Za-z])TR(?:[^A-Za-z]|$)|Turkey/i,
    '🇦🇪 阿联酋': /阿联酋|迪拜|🇦🇪|(?:^|[^A-Za-z])AE(?:[^A-Za-z]|$)|Dubai/i,
    '🇮🇹 意大利': /意大利|🇮🇹|(?:^|[^A-Za-z])IT(?:[^A-Za-z]|$)|Italy/i,
    '🇪🇸 西班牙': /西班牙|🇪🇸|(?:^|[^A-Za-z])ES(?:[^A-Za-z]|$)|Spain/i,
    '🇧🇷 巴西': /巴西|🇧🇷|(?:^|[^A-Za-z])BR(?:[^A-Za-z]|$)|Brazil/i,
    '🇲🇾 马来西亚': /马来西亚|🇲🇾|(?:^|[^A-Za-z])MY(?:[^A-Za-z]|$)|Malaysia/i,
    '🇻🇳 越南': /越南|🇻🇳|(?:^|[^A-Za-z])VN(?:[^A-Za-z]|$)|Vietnam/i,
    '🇹🇭 泰国': /泰国|🇹🇭|(?:^|[^A-Za-z])TH(?:[^A-Za-z]|$)|Thailand/i,
    '🇵🇭 菲律宾': /菲律宾|🇵🇭|(?:^|[^A-Za-z])PH(?:[^A-Za-z]|$)|Philippines/i,
    '🇮🇩 印尼': /印尼|印度尼西亚|🇮🇩|(?:^|[^A-Za-z])ID(?:[^A-Za-z]|$)|Indonesia/i,
    '🇲🇽 墨西哥': /墨西哥|🇲🇽|(?:^|[^A-Za-z])MX(?:[^A-Za-z]|$)|Mexico/i,
    '🇳🇿 新西兰': /新西兰|🇳🇿|(?:^|[^A-Za-z])NZ(?:[^A-Za-z]|$)|New\s?Zealand/i,
    '🇮🇪 爱尔兰': /爱尔兰|🇮🇪|(?:^|[^A-Za-z])IE(?:[^A-Za-z]|$)|Ireland/i,
    '🇸🇪 瑞典': /瑞典|🇸🇪|(?:^|[^A-Za-z])SE(?:[^A-Za-z]|$)|Sweden/i,
    '🇳🇴 挪威': /挪威|🇳🇴|(?:^|[^A-Za-z])NO(?:[^A-Za-z]|$)|Norway/i,
    '🇫🇮 芬兰': /芬兰|🇫🇮|(?:^|[^A-Za-z])FI(?:[^A-Za-z]|$)|Finland/i,
    '🇨🇭 瑞士': /瑞士|🇨🇭|(?:^|[^A-Za-z])CH(?:[^A-Za-z]|$)|Switzerland/i,
    '🇵🇱 波兰': /波兰|🇵🇱|(?:^|[^A-Za-z])PL(?:[^A-Za-z]|$)|Poland/i,
    '🇦🇷 阿根廷': /阿根廷|🇦🇷|(?:^|[^A-Za-z])AR(?:[^A-Za-z]|$)|Argentina/i,
    '🇪🇬 埃及': /埃及|🇪🇬|(?:^|[^A-Za-z])EG(?:[^A-Za-z]|$)|Egypt/i,
    '🇿🇦 南非': /南非|🇿🇦|(?:^|[^A-Za-z])ZA(?:[^A-Za-z]|$)|South\s?Africa/i,
    '🇺🇦 乌克兰': /乌克兰|🇺🇦|(?:^|[^A-Za-z])UA(?:[^A-Za-z]|$)|Ukraine/i,
    '🇵🇹 葡萄牙': /葡萄牙|🇵🇹|(?:^|[^A-Za-z])PT(?:[^A-Za-z]|$)|Portugal/i,
    '🇩🇰 丹麦': /丹麦|🇩🇰|(?:^|[^A-Za-z])DK(?:[^A-Za-z]|$)|Denmark/i,
    '🇧🇪 比利时': /比利时|🇧🇪|(?:^|[^A-Za-z])BE(?:[^A-Za-z]|$)|Belgium/i,
    '🇦🇹 奥地利': /奥地利|🇦🇹|(?:^|[^A-Za-z])AT(?:[^A-Za-z]|$)|Austria/i,
    '🇭🇺 匈牙利': /匈牙利|🇭🇺|(?:^|[^A-Za-z])HU(?:[^A-Za-z]|$)|Hungary/i,
    '🇨🇿 捷克': /捷克|🇨🇿|(?:^|[^A-Za-z])CZ(?:[^A-Za-z]|$)|Czech/i,
    '🇬🇷 希腊': /希腊|🇬🇷|(?:^|[^A-Za-z])GR(?:[^A-Za-z]|$)|Greece/i,
    '🇮🇱 以色列': /以色列|🇮🇱|(?:^|[^A-Za-z])IL(?:[^A-Za-z]|$)|Israel/i,
    '🇨🇱 智利': /智利|🇨🇱|(?:^|[^A-Za-z])CL(?:[^A-Za-z]|$)|Chile/i,
    '🇨🇴 哥伦比亚': /哥伦比亚|🇨🇴|(?:^|[^A-Za-z])CO(?:[^A-Za-z]|$)|Colombia/i,
    '🇵🇪 秘鲁': /秘鲁|🇵🇪|(?:^|[^A-Za-z])PE(?:[^A-Za-z]|$)|Peru/i
  };

  function parseSelfHostedName(name) {
    if (typeof name !== 'string') return null;
    const parts = name.split('|').map(part => part.trim());
    if (parts.length !== 3) return null;
    const [provider, machine, protocol] = parts;
    if (!SELF_ID_RE.test(provider) || !SELF_ID_RE.test(machine) || !SELF_PROTOCOL_RE.test(protocol)) return null;
    return {
      provider,
      machine,
      protocol,
      node: name,
      groupName: `🖥 ${provider} · ${machine}`,
      autoName: `🖥 ${provider} · ${machine}-自动`
    };
  }

  const selfHostedNodes = [];
  const machineMap = new Map();
  const countryNodes = { '🌍 其他地区': [] };
  Object.keys(countryPatterns).forEach(country => { countryNodes[country] = []; });

  for (const node of nodes) {
    const name = node && node.name;
    if (!name || PSEUDO_NODE_RE.test(name)) continue;

    const self = parseSelfHostedName(name);
    if (self) {
      selfHostedNodes.push(name);
      const key = `${self.provider}|${self.machine}`;
      if (!machineMap.has(key)) {
        machineMap.set(key, {
          provider: self.provider,
          machine: self.machine,
          groupName: self.groupName,
          autoName: self.autoName,
          nodes: []
        });
      }
      machineMap.get(key).nodes.push(name);
      continue;
    }

    let matched = '🌍 其他地区';
    for (const [country, regex] of Object.entries(countryPatterns)) {
      if (regex.test(name)) { matched = country; break; }
    }
    countryNodes[matched].push(name);
  }

  // 任一国家 >=2 节点时建立独立国家组；单节点国家并入「其他地区」。
  for (const [country, list] of Object.entries(countryNodes)) {
    if (country === '🌍 其他地区') continue;
    if (list.length < 2) {
      countryNodes['🌍 其他地区'].push(...list);
      delete countryNodes[country];
    }
  }

  const countryGroupNames = Object.keys(countryNodes)
    .filter(country => country !== '🌍 其他地区')
    .sort((a, b) => countryNodes[b].length - countryNodes[a].length);

  if (countryNodes['🌍 其他地区'].length > 0) {
    countryGroupNames.push('🌍 其他地区');
  } else {
    delete countryNodes['🌍 其他地区'];
  }

  const machines = Array.from(machineMap.values());
  const hasSelfHosted = selfHostedNodes.length > 0;
  const routeGroups = (hasSelfHosted ? [SELF_GROUP] : []).concat(countryGroupNames);
  const groups = [];

  groups.push({ name: 'Proxies', type: 'select', proxies: routeGroups });

  const appGroups = [
    'AI', 'Netflix', 'HBO', 'DisneyPlus', 'YouTube', 'Bahamut', 'Bilibili',
    'MyTVSuper', 'Telegram', 'Crypto', 'Steam', 'Epic', 'Xbox',
    'PlayStation', 'Microsoft', 'Scholar', 'Apple', 'Google', 'Tiktok'
  ];

  for (const app of appGroups) {
    let members;
    if (app === 'AI' && hasSelfHosted) {
      members = [SELF_GROUP, 'Proxies', '🎯Direct'].concat(countryGroupNames);
    } else {
      members = ['Proxies', '🎯Direct'].concat(hasSelfHosted ? [SELF_GROUP] : []).concat(countryGroupNames);
    }
    groups.push({ name: app, type: 'select', proxies: members });
  }

  groups.push({ name: '🎯Direct', type: 'select', proxies: ['DIRECT', 'Proxies'] });
  groups.push({
    name: '✈️Final',
    type: 'select',
    proxies: ['Proxies', '🎯Direct'].concat(hasSelfHosted ? [SELF_GROUP] : []).concat(countryGroupNames)
  });

  // Self-hosted V2：只暴露「总组 + 机器组」，Provider 不单独占一层。
  if (hasSelfHosted) {
    const machineGroupNames = machines.map(machine => machine.groupName);
    groups.push({
      name: SELF_GROUP,
      type: 'select',
      proxies: [SELF_AUTO].concat(machineGroupNames)
    });
    groups.push({
      name: SELF_AUTO,
      type: 'url-test',
      proxies: selfHostedNodes,
      url: TEST_URL,
      interval: 300,
      tolerance: 50
    });

    for (const machine of machines) {
      groups.push({
        name: machine.groupName,
        type: 'select',
        proxies: [machine.autoName].concat(machine.nodes)
      });
      groups.push({
        name: machine.autoName,
        type: 'url-test',
        proxies: machine.nodes,
        url: TEST_URL,
        interval: 300,
        tolerance: 50
      });
    }
  }

  for (const country of countryGroupNames) {
    const nodeList = countryNodes[country] || [];
    if (!nodeList.length) continue;
    groups.push({ name: country, type: 'select', proxies: [`${country}-自动`].concat(nodeList) });
    groups.push({
      name: `${country}-自动`,
      type: 'url-test',
      proxies: nodeList,
      url: TEST_URL,
      interval: 300,
      tolerance: 50
    });
  }

  const ruleProviders = {};
  const ruleSetUrl = 'https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/clash/';
  const ruleSets = [
    ['nexitallyy_Extra_CN_3.list', '🎯Direct'],
    ['blackmatrix7_GlobalScholar.list', 'Scholar'],
    ['blackmatrix7_myTVSUPER.list', 'MyTVSuper'],
    ['nexitallyy_Extra_Crypto.list', 'Crypto'],
    ['nexitallyy_Extra_AI.list', 'AI'],
    ['blackmatrix7_Google.list', 'Google'],
    ['ACL4SSR_YouTube.list', 'YouTube'],
    ['blackmatrix7_GameDownload.list', '🎯Direct'],
    ['ACL4SSR_LocalAreaNetwork.list', '🎯Direct'],
    ['ACL4SSR_ChinaCompanyIp.list', '🎯Direct'],
    ['HotKids_Netflix.list', 'Netflix'],
    ['ACL4SSR_Telegram.list', 'Telegram'],
    ['blackmatrix7_Steam.list', 'Steam'],
    ['blackmatrix7_Epic.list', 'Epic'],
    ['blackmatrix7_Xbox.list', 'Xbox'],
    ['blackmatrix7_PlayStation.list', 'PlayStation'],
    ['HotKids_HBO_Max.list', 'HBO'],
    ['blackmatrix7_HBOUSA.list', 'HBO'],
    ['blackmatrix7_HBOHK.list', 'HBO'],
    ['naiixi_DisneyPlus.list', 'DisneyPlus'],
    ['ACL4SSR_Bahamut.list', 'Bahamut'],
    ['HotKids_Bilibili.list', 'Bilibili'],
    ['ACL4SSR_Microsoft.list', 'Microsoft'],
    ['ACL4SSR_Apple.list', 'Apple'],
    ['blackmatrix7_TikTok.list', 'Tiktok'],
    ['ACL4SSR_ProxyLite.list', 'Proxies'],
    ['blackmatrix7_Facebook.list', 'Proxies'],
    ['nexitallyy_Extra_Proxies.list', 'Proxies'],
    ['blackmatrix7_Twitter.list', 'Proxies'],
    ['naiixi_Extra_CN.list', '🎯Direct'],
    ['naiixi_Extra_CN_2.list', '🎯Direct'],
    ['blackmatrix7_WeChat.list', '🎯Direct']
  ];

  const rules = [
    'DOMAIN-SUFFIX,jsdelivr.net,🎯Direct',
    'DOMAIN-SUFFIX,githubusercontent.com,🎯Direct',
    'DOMAIN-SUFFIX,github.com,🎯Direct',
    'DOMAIN-SUFFIX,raw.githubusercontent.com,🎯Direct',
    'DOMAIN-SUFFIX,creamdata.xyz,🎯Direct'
  ];

  ruleSets.forEach(([file, policy], idx) => {
    const providerName = `provider_${idx}`;
    ruleProviders[providerName] = {
      type: 'http',
      behavior: 'classical',
      format: 'text',
      url: ruleSetUrl + file,
      path: `./providers/${file}`,
      interval: 86400
    };
    rules.push(`RULE-SET,${providerName},${policy}`);
  });

  rules.push('GEOIP,CN,🎯Direct,no-resolve');
  rules.push('MATCH,✈️Final');

  config.proxies = nodes;
  config['proxy-groups'] = groups;
  config['rule-providers'] = ruleProviders;
  config.rules = rules;
  return config;
}
