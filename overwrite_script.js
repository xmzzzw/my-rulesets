// ============================================================
// my-rulesets 覆写脚本（FlClash / Clash Verge Rev / Mihomo）
// ------------------------------------------------------------
// 规格：
//   - 保留订阅节点
//   - 自建 VPS 节点（当前：DMIT | ...）独立于国家分组
//   - DMIT 自建组：🛠 DMIT自建 -> 🛠 DMIT自建-自动 -> 具体协议节点
//   - 动态国家分组：>=2 节点建组，否则并入 🌍 其他地区
//   - 应用组 + Direct/Final + 32 个 rule-providers
//
// 安全：公开仓库仅识别节点命名，不包含任何 VPS IP/PSK/密码。
// ============================================================
function main(config, profileName) {
  const nodes = config.proxies || [];

  const PSEUDO_NODE_RE = /Traffic|Expire|流量|到期|剩余|套餐|官网|订阅|^Panel|^www\.|creamdata\.xyz|节点|主页/i;
  const DMIT_NODE_RE = /^DMIT\s*\|/i;
  const DMIT_GROUP = '🛠 DMIT自建';
  const DMIT_AUTO = '🛠 DMIT自建-自动';
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

  const dmitNodes = [];
  const countryNodes = { '🌍 其他地区': [] };
  Object.keys(countryPatterns).forEach(country => { countryNodes[country] = []; });

  for (const node of nodes) {
    const name = node && node.name;
    if (!name || PSEUDO_NODE_RE.test(name)) continue;
    if (DMIT_NODE_RE.test(name)) {
      dmitNodes.push(name);
      continue;
    }
    let matched = '🌍 其他地区';
    for (const [country, regex] of Object.entries(countryPatterns)) {
      if (regex.test(name)) { matched = country; break; }
    }
    countryNodes[matched].push(name);
  }

  for (const [country, list] of Object.entries(countryNodes)) {
    if (country === '🌍 其他地区') continue;
    if (list.length < 2) {
      countryNodes['🌍 其他地区'].push(...list);
      delete countryNodes[country];
    }
  }

  const countryGroupNames = Object.keys(countryNodes)
    .filter(c => c !== '🌍 其他地区')
    .sort((a, b) => countryNodes[b].length - countryNodes[a].length);
  if (countryNodes['🌍 其他地区'].length > 0) {
    countryGroupNames.push('🌍 其他地区');
  } else {
    delete countryNodes['🌍 其他地区'];
  }

  const hasDMIT = dmitNodes.length > 0;
  const routeGroups = (hasDMIT ? [DMIT_GROUP] : []).concat(countryGroupNames);
  const groups = [];

  groups.push({ name: 'Proxies', type: 'select', proxies: routeGroups });

  const appGroups = [
    'AI', 'Netflix', 'HBO', 'DisneyPlus', 'YouTube', 'Bahamut', 'Bilibili',
    'MyTVSuper', 'Telegram', 'Crypto', 'Steam', 'Epic', 'Xbox',
    'PlayStation', 'Microsoft', 'Scholar', 'Apple', 'Google', 'Tiktok'
  ];
  for (const app of appGroups) {
    let members;
    if (app === 'AI' && hasDMIT) {
      members = [DMIT_GROUP, 'Proxies', '🎯Direct'].concat(countryGroupNames);
    } else {
      members = ['Proxies', '🎯Direct'].concat(hasDMIT ? [DMIT_GROUP] : []).concat(countryGroupNames);
    }
    groups.push({ name: app, type: 'select', proxies: members });
  }

  groups.push({ name: '🎯Direct', type: 'select', proxies: ['DIRECT', 'Proxies'] });
  groups.push({
    name: '✈️Final', type: 'select',
    proxies: ['Proxies', '🎯Direct'].concat(hasDMIT ? [DMIT_GROUP] : []).concat(countryGroupNames)
  });

  // 自建 VPS 组放在 Final 后、国家分组前；客户端 UI 与现有国家组逻辑一致。
  if (hasDMIT) {
    groups.push({ name: DMIT_GROUP, type: 'select', proxies: [DMIT_AUTO].concat(dmitNodes) });
    groups.push({
      name: DMIT_AUTO, type: 'url-test', proxies: dmitNodes,
      url: TEST_URL, interval: 300, tolerance: 50
    });
  }

  for (const country of countryGroupNames) {
    const nodeList = countryNodes[country] || [];
    if (!nodeList.length) continue;
    groups.push({ name: country, type: 'select', proxies: [`${country}-自动`].concat(nodeList) });
    groups.push({
      name: `${country}-自动`, type: 'url-test', proxies: nodeList,
      url: TEST_URL, interval: 300, tolerance: 50
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
      type: 'http', behavior: 'classical', format: 'text',
      url: ruleSetUrl + file, path: `./providers/${file}`, interval: 86400
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
