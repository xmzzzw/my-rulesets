// 覆写脚本：将机场订阅配置改造为「my-rulesets」规格
// 兼容 FlClash（脚本模式）与 Clash Verge（脚本 profile）
// 保留订阅节点，替换策略组/规则为自定义结构
function main(config) {
  // ============ 1. 保留订阅节点 ============
  const nodes = config.proxies || [];
  
  // ============ 2. 定义策略组 ============
  // 国家分组引用（根据订阅节点名自动归类）
  const countries = ['🇭🇰 香港', '🇺🇸 美国', '🇯🇵 日本', '🇸🇬 新加坡', '🇨🇳 台湾', '🇰🇷 韩国'];
  
  // 按国家归类节点（从节点名识别国家）
  const countryNodes = {
    '🇭🇰 香港': [], '🇺🇸 美国': [], '🇯🇵 日本': [],
    '🇸🇬 新加坡': [], '🇨🇳 台湾': [], '🇰🇷 韩国': [], '🌍 其他地区': []
  };
  
  const countryPrefixes = {
    '🇭🇰 香港': /香港|🇭🇰|HK|Hong\s?Kong/i,
    '🇺🇸 美国': /美国|🇺🇸|🇺🇲|US|America/i,
    '🇯🇵 日本': /日本|🇯🇵|JP|Japan/i,
    '🇸🇬 新加坡': /新加坡|🇸🇬|SG|Singapore/i,
    '🇨🇳 台湾': /台湾|🇨🇳|🇹🇼|TW|Taiwan/i,
    '🇰🇷 韩国': /韩国|🇰🇷|KR|Korea/i
  };
  
  for (const node of nodes) {
    // 跳过 Traffic/Expire 显示节点
    if (/Traffic|Expire|流量|到期/i.test(node.name)) continue;
    let matched = '🌍 其他地区';
    for (const [country, regex] of Object.entries(countryPrefixes)) {
      if (regex.test(node.name)) { matched = country; break; }
    }
    countryNodes[matched].push(node.name);
  }
  
  // 构建国家分组（select + url-test 自动选择）
  const groups = [];
  
  // 顶层节点选择组（引用国家分组）
  const groupNames = ['🇭🇰 香港', '🇺🇸 美国', '🇯🇵 日本', '🇸🇬 新加坡', '🇨🇳 台湾', '🇰🇷 韩国', '🌍 其他地区'];
  groups.push({
    name: 'Proxies', type: 'select',
    proxies: groupNames
  });
  
  // 各国家分组
  for (const country of groupNames) {
    const nodeList = countryNodes[country] || [];
    if (nodeList.length === 0) continue;
    groups.push({
      name: country, type: 'select',
      proxies: [`${country}-自动`].concat(nodeList)
    });
    groups.push({
      name: `${country}-自动`, type: 'url-test',
      url: 'http://www.gstatic.com/generate_204',
      interval: 300, tolerance: 50,
      proxies: nodeList
    });
  }
  
  // 应用策略组（引用国家分组）
  const appGroups = [
    'Netflix', 'HBO', 'DisneyPlus', 'YouTube', 'Bahamut', 'Bilibili',
    'MyTVSuper', 'AI', 'Telegram', 'Crypto', 'Steam', 'Epic', 'Xbox',
    'PlayStation', 'Microsoft', 'Scholar', 'Apple', 'Google', 'Tiktok'
  ];
  for (const app of appGroups) {
    groups.push({
      name: app, type: 'select',
      proxies: ['Proxies', '🎯Direct'].concat(groupNames)
    });
  }
  
  // 直连组
  groups.push({ name: '🎯Direct', type: 'select', proxies: ['DIRECT', 'Proxies'] });
  
  // Final 兜底
  groups.push({
    name: '✈️Final', type: 'select',
    proxies: ['Proxies', '🎯Direct'].concat(groupNames)
  });
  
  // ============ 3. 注入 rule-providers（引用 GitHub 规则集）============
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
  
  const rules = [];
  ruleSets.forEach(([file, policy], idx) => {
    const providerName = `provider_${idx}`;
    ruleProviders[providerName] = {
      type: 'http', behavior: 'classical', format: 'text',
      url: ruleSetUrl + file,
      path: `./providers/${file}`, interval: 86400
    };
    rules.push(`RULE-SET,${providerName},${policy}`);
  });
  
  // GEOIP + MATCH
  rules.push('GEOIP,CN,🎯Direct,no-resolve');
  rules.push('MATCH,✈️Final');
  
  // ============ 4. 组装并返回 ============
  config.proxies = nodes;
  config['proxy-groups'] = groups;
  config['rule-providers'] = ruleProviders;
  config.rules = rules;
  return config;
}
