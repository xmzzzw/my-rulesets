// ============================================================
// my-rulesets 覆写脚本（双端兼容）
// ------------------------------------------------------------
// 将机场订阅配置改造为「my-rulesets」规格：保留订阅节点，
// 重建策略组（国家分组 + url-test 自动 + 应用组 + Direct/Final），
// 注入 rule-providers（引用 my-rulesets 的 clash/ 规则集）并重写 rules。
//
// 适配端：
//   - FlClash（安卓）：配置 → 覆写 → 脚本模式，从 URL 直接导入本文件
//   - Clash Verge Rev（Windows）：订阅右键 → 新建脚本 profile → 编辑文件 → 粘贴本文件
//
// 入口签名 function main(config, profileName)：
//   - FlClash 只传 config，profileName 为 undefined，不影响运行
//   - Clash Verge 会传 config, profileName，可利用 profileName 区分多订阅
//
// 注意：Clash Verge 的脚本 profile 不支持从 URL 直接拉取脚本，
// 只能本地文件（粘贴或 curl 同步），详见 OVERWRITE.md。
// ============================================================
function main(config, profileName) {
  // ============ 1. 保留订阅节点 ============
  const nodes = config.proxies || [];

  // ============ 2. 定义策略组 ============

  // 按国家归类节点（从节点名识别国家）
  // 完整国家映射：emoji / 国家代码 / 中文名 均可识别
  // ⚠️ 国家代码须加非字母边界 (?:^|[^A-Za-z])XX(?:[^A-Za-z]|$)（与 openclash_overwrite.sh 一致）：
  //   裸 "US"/"ID"/"IN" 会误命中 Status/Provider/Valid 等英文词 → 误归类/误建组
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

  // 归类节点（跳过 Traffic/Expire 显示节点）
  const countryNodes = { '🌍 其他地区': [] };
  for (const [country] of Object.entries(countryPatterns)) countryNodes[country] = [];
  for (const node of nodes) {
    // 伪节点过滤（与 openclash_overwrite.sh 对齐）：流量/到期/套餐/官网/面板等显示节点不进组
    if (/Traffic|Expire|流量|到期|剩余|套餐|官网|订阅|^Panel|^www\.|creamdata\.xyz|节点|主页/i.test(node.name)) continue;
    let matched = '🌍 其他地区';
    for (const [country, regex] of Object.entries(countryPatterns)) {
      if (regex.test(node.name)) { matched = country; break; }
    }
    countryNodes[matched].push(node.name);
  }

  // 动态国家分组：任一国家节点 ≥2 就建独立分组，否则并入 🌍 其他地区
  for (const [country, list] of Object.entries(countryNodes)) {
    if (country === '🌍 其他地区') continue;
    if (list.length < 2) {
      countryNodes['🌍 其他地区'].push(...list);
      delete countryNodes[country];
    }
  }
  // 国家分组顺序：节点多的在前；🌍 其他地区放最后
  // ⚠️ 「其他地区」仅在有成员时才加入引用（与 openclash_overwrite.sh 一致）：
  //   否则所有节点都命中国家时，Proxies/应用组会引用不存在的空组 → mihomo fatal 启动失败
  const groupNames = Object.keys(countryNodes)
    .filter(c => c !== '🌍 其他地区')
    .sort((a, b) => countryNodes[b].length - countryNodes[a].length);
  if (countryNodes['🌍 其他地区'].length > 0) {
    groupNames.push('🌍 其他地区');
  } else {
    delete countryNodes['🌍 其他地区'];
  }

  // 构建策略组（顺序：Proxies → 应用组 → Direct → Final → 国家分组）
  const groups = [];

  // 顶层节点选择组（引用国家分组）
  groups.push({
    name: 'Proxies', type: 'select',
    proxies: groupNames
  });

  // 应用策略组（引用国家分组）
  // 应用组顺序与 openclash_overwrite.sh / convert.py 严格一致：AI 在首位
  const appGroups = [
    'AI', 'Netflix', 'HBO', 'DisneyPlus', 'YouTube', 'Bahamut', 'Bilibili',
    'MyTVSuper', 'Telegram', 'Crypto', 'Steam', 'Epic', 'Xbox',
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

  // 国家分组（放 Final 之后，与 OpenClash 规格一致）
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

  // ============ 3. 注入 rule-providers（引用 GitHub 规则集）============
  const ruleProviders = {};

  // 规则集地址源。默认 raw.githubusercontent.com；若下载失败/被墙，
  // 改用 jsdelivr CDN：'https://testingcf.jsdelivr.net/gh/xmzzzw/my-rulesets@main/clash/'
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
  // 内部流量/规则集下载直连放【最前】（与 openclash_overwrite.sh / convert.py 一致），
  // 避免 mihomo 拉 rule-provider 时命中 MATCH 走代理导致 EOF 死循环（OpenClash 踩坑）
  rules.push('DOMAIN-SUFFIX,jsdelivr.net,🎯Direct');
  rules.push('DOMAIN-SUFFIX,githubusercontent.com,🎯Direct');
  rules.push('DOMAIN-SUFFIX,github.com,🎯Direct');
  rules.push('DOMAIN-SUFFIX,raw.githubusercontent.com,🎯Direct');
  rules.push('DOMAIN-SUFFIX,creamdata.xyz,🎯Direct');
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
