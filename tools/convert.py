#!/usr/bin/env python3
"""
my-rulesets 配置转换工具
========================

将代理节点转换为 my-rulesets 的统一策略结构。
当前自建节点约定：节点名以 ``DMIT |`` 开头时，视为 DMIT 自建节点：
- 不参加国家分组
- 不进入「🌍 其他地区」
- 自动生成「🛠 DMIT自建」和「🛠 DMIT自建-自动」
- AI 组优先显示 DMIT 自建出口

公开仓库只保存分组逻辑，不保存 VPS IP、密码、PSK 或私钥。
"""
import argparse
import os
import re
from collections import defaultdict

COUNTRY_MAP = {
    'HK': '🇭🇰 香港', 'SG': '🇸🇬 新加坡', 'JP': '🇯🇵 日本',
    'US': '🇺🇸 美国', 'UK': '🇬🇧 英国', 'GB': '🇬🇧 英国',
    'TW': '🇨🇳 台湾', 'DE': '🇩🇪 德国', 'AU': '🇦🇺 澳大利亚',
    'KR': '🇰🇷 韩国', 'CA': '🇨🇦 加拿大', 'NL': '🇳🇱 荷兰',
    'IN': '🇮🇳 印度', 'FR': '🇫🇷 法国', 'RU': '🇷🇺 俄罗斯',
    'TR': '🇹🇷 土耳其', 'PH': '🇵🇭 菲律宾', 'ID': '🇮🇩 印尼',
    'VN': '🇻🇳 越南', 'ES': '🇪🇸 西班牙', 'UA': '🇺🇦 乌克兰',
    'NO': '🇳🇴 挪威', 'CH': '🇨🇭 瑞士', 'SE': '🇸🇪 瑞典',
    'IE': '🇮🇪 爱尔兰', 'MY': '🇲🇾 马来西亚', 'TH': '🇹🇭 泰国',
    'AE': '🇦🇪 阿联酋', 'EG': '🇪🇬 埃及', 'BR': '🇧🇷 巴西',
    'IT': '🇮🇹 意大利', 'MX': '🇲🇽 墨西哥', 'AR': '🇦🇷 阿根廷',
    'NZ': '🇳🇿 新西兰', 'PL': '🇵🇱 波兰', 'PT': '🇵🇹 葡萄牙',
    'FI': '🇫🇮 芬兰', 'DK': '🇩🇰 丹麦', 'BE': '🇧🇪 比利时',
    'AT': '🇦🇹 奥地利', 'HU': '🇭🇺 匈牙利', 'CZ': '🇨🇿 捷克',
    'GR': '🇬🇷 希腊', 'IL': '🇮🇱 以色列', 'ZA': '🇿🇦 南非',
    'CL': '🇨🇱 智利', 'CO': '🇨🇴 哥伦比亚', 'PE': '🇵🇪 秘鲁',
}

EMOJI_MAP = {
    '🇭🇰': '香港', '🇸🇬': '新加坡', '🇯🇵': '日本', '🇺🇸': '美国',
    '🇬🇧': '英国', '🇨🇳': '台湾', '🇹🇼': '台湾', '🇩🇪': '德国',
    '🇦🇺': '澳大利亚', '🇰🇷': '韩国', '🇨🇦': '加拿大', '🇳🇱': '荷兰',
    '🇮🇳': '印度', '🇫🇷': '法国', '🇷🇺': '俄罗斯', '🇹🇷': '土耳其',
    '🇵🇭': '菲律宾', '🇮🇩': '印尼', '🇻🇳': '越南', '🇪🇸': '西班牙',
    '🇺🇦': '乌克兰', '🇳🇴': '挪威', '🇨🇭': '瑞士', '🇸🇪': '瑞典',
    '🇮🇪': '爱尔兰', '🇲🇾': '马来西亚', '🇹🇭': '泰国', '🇦🇪': '阿联酋',
    '🇪🇬': '埃及', '🇧🇷': '巴西', '🇮🇹': '意大利', '🇲🇽': '墨西哥',
    '🇦🇷': '阿根廷', '🇳🇿': '新西兰', '🇵🇱': '波兰', '🇵🇹': '葡萄牙',
    '🇫🇮': '芬兰', '🇩🇰': '丹麦', '🇧🇪': '比利时', '🇦🇹': '奥地利',
    '🇭🇺': '匈牙利', '🇨🇿': '捷克', '🇬🇷': '希腊', '🇮🇱': '以色列',
    '🇿🇦': '南非', '🇨🇱': '智利', '🇨🇴': '哥伦比亚', '🇵🇪': '秘鲁',
}

CN_NAME_MAP = {
    '香港': '🇭🇰 香港', '新加坡': '🇸🇬 新加坡', '日本': '🇯🇵 日本',
    '美国': '🇺🇸 美国', '英国': '🇬🇧 英国', '台湾': '🇨🇳 台湾',
    '德国': '🇩🇪 德国', '澳大利亚': '🇦🇺 澳大利亚', '韩国': '🇰🇷 韩国',
    '加拿大': '🇨🇦 加拿大', '荷兰': '🇳🇱 荷兰', '印度': '🇮🇳 印度',
    '法国': '🇫🇷 法国', '俄罗斯': '🇷🇺 俄罗斯', '土耳其': '🇹🇷 土耳其',
    '菲律宾': '🇵🇭 菲律宾', '印尼': '🇮🇩 印尼', '越南': '🇻🇳 越南',
    '西班牙': '🇪🇸 西班牙', '乌克兰': '🇺🇦 乌克兰', '挪威': '🇳🇴 挪威',
    '瑞士': '🇨🇭 瑞士', '瑞典': '🇸🇪 瑞典', '爱尔兰': '🇮🇪 爱尔兰',
    '马来西亚': '🇲🇾 马来西亚', '泰国': '🇹🇭 泰国', '阿联酋': '🇦🇪 阿联酋',
    '埃及': '🇪🇬 埃及', '巴西': '🇧🇷 巴西', '意大利': '🇮🇹 意大利',
    '墨西哥': '🇲🇽 墨西哥', '阿根廷': '🇦🇷 阿根廷', '新西兰': '🇳🇿 新西兰',
    '波兰': '🇵🇱 波兰', '葡萄牙': '🇵🇹 葡萄牙', '芬兰': '🇫🇮 芬兰',
    '丹麦': '🇩🇰 丹麦', '比利时': '🇧🇪 比利时', '奥地利': '🇦🇹 奥地利',
    '匈牙利': '🇭🇺 匈牙利', '捷克': '🇨🇿 捷克', '希腊': '🇬🇷 希腊',
    '以色列': '🇮🇱 以色列', '南非': '🇿🇦 南非', '智利': '🇨🇱 智利',
    '哥伦比亚': '🇨🇴 哥伦比亚', '秘鲁': '🇵🇪 秘鲁',
}

PROTOCOLS = [
    'ss', 'ssr', 'trojan', 'anytls', 'vmess', 'vless', 'hysteria2',
    'hysteria', 'tuic', 'wireguard', 'snell', 'http', 'socks5'
]
PSEUDO_NODE_RE = re.compile(
    r'Traffic|Expire|流量|到期|剩余|套餐|官网|订阅|^Panel|^www\.|creamdata\.xyz|节点|主页', re.I
)
DMIT_NODE_RE = re.compile(r'^DMIT\s*\|', re.I)
DMIT_GROUP = '🛠 DMIT自建'
DMIT_AUTO = '🛠 DMIT自建-自动'
TEST_URL = 'http://www.gstatic.com/generate_204'


def detect_country(node_name):
    for emoji, cn in EMOJI_MAP.items():
        if emoji in node_name:
            return f'{emoji} {cn}'
    for code, full in COUNTRY_MAP.items():
        if re.search(rf'\b{re.escape(code)}\b', node_name, re.I):
            return full
    for cn, full in CN_NAME_MAP.items():
        if cn in node_name:
            return full
    return '🌍 其他地区'


def detect_protocol(line):
    for proto in PROTOCOLS:
        if re.search(rf' = {re.escape(proto)}, ', line) or f'type: {proto}' in line:
            return proto
    return None


def detect_node_protocols(lines):
    protos = defaultdict(int)
    for line in lines:
        proto = detect_protocol(line)
        if proto:
            protos[proto] += 1
    return dict(protos)


def read_input(path_or_url):
    if path_or_url.startswith(('http://', 'https://')):
        import urllib.request
        req = urllib.request.Request(path_or_url, headers={'User-Agent': 'ClashForWindows/0.20.39'})
        try:
            opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
            with opener.open(req, timeout=30) as r:
                return r.read().decode('utf-8', errors='replace')
        except Exception:
            with urllib.request.urlopen(req, timeout=30) as r:
                return r.read().decode('utf-8', errors='replace')
    with open(path_or_url, encoding='utf-8') as f:
        return f.read()


def parse_proxies(content):
    nodes = []
    for line in content.splitlines():
        m = re.match(r'^(.+?) = ([\w-]+), (.+)$', line.strip())
        if not m:
            continue
        name, proto, _ = m.groups()
        if proto in PROTOCOLS:
            nodes.append({'name': name.strip(), 'proto': proto, 'line': line.strip()})
    return nodes


def is_surge_conf(content):
    return '[Proxy]' in content and any(f' = {proto}, ' in content for proto in PROTOCOLS)


def build_policy_groups(nodes, single_node_merge=True):
    by_country = defaultdict(list)
    dmit_nodes = []

    for node in nodes:
        name = node['name']
        if PSEUDO_NODE_RE.search(name):
            continue
        if DMIT_NODE_RE.search(name):
            dmit_nodes.append(name)
            continue
        by_country[detect_country(name)].append(name)

    if single_node_merge:
        singletons = [c for c, names in by_country.items() if c != '🌍 其他地区' and len(names) <= 1]
        for country in singletons:
            by_country['🌍 其他地区'].extend(by_country[country])
            del by_country[country]

    countries = sorted(
        (c for c in by_country if c != '🌍 其他地区'),
        key=lambda c: -len(by_country[c])
    )
    if by_country.get('🌍 其他地区'):
        countries.append('🌍 其他地区')

    has_dmit = bool(dmit_nodes)
    route_groups = ([DMIT_GROUP] if has_dmit else []) + countries
    groups = [{'name': 'Proxies', 'type': 'select', 'members': route_groups}]

    app_groups = [
        'AI', 'Netflix', 'HBO', 'DisneyPlus', 'YouTube', 'Bahamut', 'Bilibili',
        'MyTVSuper', 'Telegram', 'Crypto', 'Steam', 'Epic', 'Xbox', 'PlayStation',
        'Microsoft', 'Scholar', 'Apple', 'Google', 'Tiktok'
    ]
    for app in app_groups:
        if app == 'AI' and has_dmit:
            members = [DMIT_GROUP, 'Proxies', '🎯Direct'] + countries
        else:
            members = ['Proxies', '🎯Direct'] + ([DMIT_GROUP] if has_dmit else []) + countries
        groups.append({'name': app, 'type': 'select', 'members': members})

    groups.append({'name': '🎯Direct', 'type': 'select', 'members': ['DIRECT', 'Proxies']})
    groups.append({
        'name': '✈️Final', 'type': 'select',
        'members': ['Proxies', '🎯Direct'] + ([DMIT_GROUP] if has_dmit else []) + countries
    })

    if has_dmit:
        groups.append({'name': DMIT_GROUP, 'type': 'select', 'members': [DMIT_AUTO] + dmit_nodes})
        groups.append({
            'name': DMIT_AUTO, 'type': 'url-test', 'members': dmit_nodes,
            'url': TEST_URL, 'interval': 300, 'tolerance': 50
        })

    for country in countries:
        names = by_country[country]
        auto = f'{country}-自动'
        groups.append({'name': country, 'type': 'select', 'members': [auto] + names})
        groups.append({
            'name': auto, 'type': 'url-test', 'members': names,
            'url': TEST_URL, 'interval': 300, 'tolerance': 50
        })

    return groups, by_country, dmit_nodes


def build_rules():
    base = 'https://raw.githubusercontent.com/xmzzzw/my-rulesets/main'
    ruleset_map = [
        ('nexitallyy_Extra_CN_3.list', '🎯Direct'), ('blackmatrix7_GlobalScholar.list', 'Scholar'),
        ('blackmatrix7_myTVSUPER.list', 'MyTVSuper'), ('nexitallyy_Extra_Crypto.list', 'Crypto'),
        ('nexitallyy_Extra_AI.list', 'AI'), ('blackmatrix7_Google.list', 'Google'),
        ('ACL4SSR_YouTube.list', 'YouTube'), ('blackmatrix7_GameDownload.list', '🎯Direct'),
        ('HotKids_Netflix.list', 'Netflix'), ('ACL4SSR_Telegram.list', 'Telegram'),
        ('blackmatrix7_Steam.list', 'Steam'), ('blackmatrix7_Epic.list', 'Epic'),
        ('blackmatrix7_Xbox.list', 'Xbox'), ('blackmatrix7_PlayStation.list', 'PlayStation'),
        ('HotKids_HBO_Max.list', 'HBO'), ('blackmatrix7_HBOUSA.list', 'HBO'),
        ('blackmatrix7_HBOHK.list', 'HBO'), ('naiixi_DisneyPlus.list', 'DisneyPlus'),
        ('ACL4SSR_Bahamut.list', 'Bahamut'), ('HotKids_Bilibili.list', 'Bilibili'),
        ('ACL4SSR_Microsoft.list', 'Microsoft'), ('ACL4SSR_Apple.list', 'Apple'),
        ('blackmatrix7_TikTok.list', 'Tiktok'), ('ACL4SSR_ProxyLite.list', 'Proxies'),
        ('blackmatrix7_Facebook.list', 'Proxies'), ('nexitallyy_Extra_Proxies.list', 'Proxies'),
        ('blackmatrix7_Twitter.list', 'Proxies'), ('naiixi_Extra_CN.list', '🎯Direct'),
        ('naiixi_Extra_CN_2.list', '🎯Direct'), ('blackmatrix7_WeChat.list', '🎯Direct'),
    ]
    rules = [f'RULE-SET,{base}/{file},{policy},update-interval=86400' for file, policy in ruleset_map]
    rules += ['GEOIP,CN,🎯Direct', 'FINAL,✈️Final']
    return rules


def to_surge(nodes, groups, rules):
    out = ['[Proxy]']
    out.extend(n['line'] for n in nodes)
    out += ['', '[Proxy Group]']
    for group in groups:
        members = ', '.join(group['members'])
        if group['type'] == 'select':
            out.append(f"{group['name']} = select, {members}")
        elif group['type'] == 'url-test':
            out.append(
                f"{group['name']} = url-test, {members}, url={group['url']}, "
                f"interval={group['interval']}, tolerance={group['tolerance']}"
            )
    out += ['', '[Rule]']
    out.extend(rules)
    return '\n'.join(out)


def _surge_params(line):
    parts = [p.strip() for p in line.split(',')]
    params = {}
    for part in parts[3:]:
        if '=' in part:
            key, value = part.split('=', 1)
            params[key.strip()] = value.strip()
    return parts, params


def to_clash(nodes, groups, _rules):
    import yaml

    config = {
        'mixed-port': 7890, 'allow-lan': False, 'mode': 'rule',
        'log-level': 'warning', 'ipv6': True,
        'dns': {
            'enable': True, 'enhanced-mode': 'fake-ip', 'fake-ip-range': '198.18.0.1/16',
            'fake-ip-filter': ['*.lan', '+.local', '+.msftconnecttest.com', '+.msftncsi.com'],
            'default-nameserver': ['223.5.5.5', '119.29.29.29'],
            'nameserver': ['https://223.5.5.5/dns-query', 'https://doh.pub/dns-query'],
            'fallback': ['https://1.1.1.1/dns-query', 'https://dns.google/dns-query'],
            'fallback-filter': {'geoip': True, 'geoip-code': 'CN'},
        },
        'proxies': [], 'proxy-groups': [], 'rule-providers': {}, 'rules': [],
    }

    for node in nodes:
        parts, params = _surge_params(node['line'])
        if len(parts) < 3:
            continue
        name, proto = node['name'], node['proto']
        proxy = {'name': name, 'type': proto, 'server': parts[1], 'port': int(parts[2])}
        if proto == 'ss':
            proxy.update({
                'cipher': params.get('encrypt-method', 'aes-256-gcm'),
                'password': params.get('password', ''),
                'udp': params.get('udp-relay', 'true').lower() == 'true'
            })
        elif proto in ('trojan', 'anytls'):
            proxy['password'] = params.get('password', '')
            if 'sni' in params:
                proxy['sni'] = params['sni']
            proxy['skip-cert-verify'] = params.get('skip-cert-verify', 'false').lower() == 'true'
            proxy['udp'] = params.get('udp-relay', 'true').lower() == 'true'
        elif proto == 'vmess':
            proxy['uuid'] = params.get('uuid', '')
            proxy['alterId'] = int(params.get('alterId', '0') or '0')
            proxy['cipher'] = params.get('encrypt-method', 'auto')
            proxy['udp'] = True
        elif proto == 'snell':
            proxy['psk'] = params.get('psk', '')
            proxy['version'] = int(params.get('version', '5') or '5')
            proxy['udp'] = True
        elif proto == 'hysteria2':
            proxy['password'] = params.get('password', '')
            if 'sni' in params:
                proxy['sni'] = params['sni']
            proxy['skip-cert-verify'] = params.get('skip-cert-verify', 'false').lower() == 'true'
        config['proxies'].append(proxy)

    for item in groups:
        group = {'name': item['name'], 'type': item['type'], 'proxies': item['members']}
        if item['type'] == 'url-test':
            group.update({
                'url': item.get('url', TEST_URL), 'interval': int(item.get('interval', 300)),
                'tolerance': int(item.get('tolerance', 50))
            })
        config['proxy-groups'].append(group)

    ruleset_files = [
        ('nexitallyy_Extra_CN_3.list', '🎯Direct'), ('blackmatrix7_GlobalScholar.list', 'Scholar'),
        ('blackmatrix7_myTVSUPER.list', 'MyTVSuper'), ('nexitallyy_Extra_Crypto.list', 'Crypto'),
        ('nexitallyy_Extra_AI.list', 'AI'), ('blackmatrix7_Google.list', 'Google'),
        ('ACL4SSR_YouTube.list', 'YouTube'), ('blackmatrix7_GameDownload.list', '🎯Direct'),
        ('ACL4SSR_LocalAreaNetwork.list', '🎯Direct'), ('ACL4SSR_ChinaCompanyIp.list', '🎯Direct'),
        ('HotKids_Netflix.list', 'Netflix'), ('ACL4SSR_Telegram.list', 'Telegram'),
        ('blackmatrix7_Steam.list', 'Steam'), ('blackmatrix7_Epic.list', 'Epic'),
        ('blackmatrix7_Xbox.list', 'Xbox'), ('blackmatrix7_PlayStation.list', 'PlayStation'),
        ('HotKids_HBO_Max.list', 'HBO'), ('blackmatrix7_HBOUSA.list', 'HBO'),
        ('blackmatrix7_HBOHK.list', 'HBO'), ('naiixi_DisneyPlus.list', 'DisneyPlus'),
        ('ACL4SSR_Bahamut.list', 'Bahamut'), ('HotKids_Bilibili.list', 'Bilibili'),
        ('ACL4SSR_Microsoft.list', 'Microsoft'), ('ACL4SSR_Apple.list', 'Apple'),
        ('blackmatrix7_TikTok.list', 'Tiktok'), ('ACL4SSR_ProxyLite.list', 'Proxies'),
        ('blackmatrix7_Facebook.list', 'Proxies'), ('nexitallyy_Extra_Proxies.list', 'Proxies'),
        ('blackmatrix7_Twitter.list', 'Proxies'), ('naiixi_Extra_CN.list', '🎯Direct'),
        ('naiixi_Extra_CN_2.list', '🎯Direct'), ('blackmatrix7_WeChat.list', '🎯Direct'),
    ]
    for domain in ('jsdelivr.net', 'githubusercontent.com', 'github.com', 'raw.githubusercontent.com', 'creamdata.xyz'):
        config['rules'].append(f'DOMAIN-SUFFIX,{domain},🎯Direct')

    base = 'https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/clash/'
    for i, (file, policy) in enumerate(ruleset_files):
        pid = f'provider_{i}'
        config['rule-providers'][pid] = {
            'type': 'http', 'behavior': 'classical', 'format': 'text',
            'url': base + file, 'path': f'./providers/{file}', 'interval': 86400,
        }
        config['rules'].append(f'RULE-SET,{pid},{policy}')
    config['rules'] += ['GEOIP,CN,🎯Direct,no-resolve', 'MATCH,✈️Final']
    return yaml.dump(config, allow_unicode=True, sort_keys=False, default_flow_style=False)


def auto_output_name(args, protos):
    src = args.input or ''
    name = 'MyAirport'
    m = re.search(r'filename=([^&]+)', src)
    if m:
        name = m.group(1).split('.')[0].split('_')[0]
    elif src.startswith('http'):
        host = re.sub(r'^https?://', '', src).split('/')[0]
        if host:
            name = host.split('.')[0].capitalize()
    else:
        base = os.path.basename(src)
        if base and '.' in base:
            name = base.rsplit('.', 1)[0]

    proto = args.protocol or (max(protos.items(), key=lambda x: x[1])[0] if protos else 'mixed')
    fmt = args.format if args.format in ('surge', 'clash') else 'clash'
    return f"{name}_{proto}_{'Surge' if fmt == 'surge' else 'Clash'}_MyRules.{'conf' if fmt == 'surge' else 'yaml'}"


def main():
    parser = argparse.ArgumentParser(description='my-rulesets 配置转换工具')
    parser.add_argument('--input', required=True, help='输入文件或订阅 URL')
    parser.add_argument('--format', choices=['surge', 'clash', 'auto'], default='auto')
    parser.add_argument('--no-merge-single', action='store_true')
    parser.add_argument('--subscription-refresh', action='store_true')
    parser.add_argument('--output')
    parser.add_argument('--protocol')
    args = parser.parse_args()

    content = read_input(args.input)
    nodes = parse_proxies(content)
    if not nodes:
        print(f'⚠️ 未识别到节点。输入前 200 字符:\n{content[:200]}')
        return 2

    protos = detect_node_protocols([n['line'] for n in nodes])
    groups, by_country, dmit_nodes = build_policy_groups(nodes, not args.no_merge_single)
    print(f'✅ 识别到 {len(nodes)} 个节点，协议分布: {protos}')
    if dmit_nodes:
        print(f'   🛠 DMIT自建: {len(dmit_nodes)}')
    for country, names in sorted(by_country.items(), key=lambda x: -len(x[1])):
        if names:
            print(f'   {country}: {len(names)}')

    if args.format == 'auto':
        args.format = 'surge' if is_surge_conf(content) else 'clash'

    rules = build_rules()
    output = to_clash(nodes, groups, rules) if args.format == 'clash' else to_surge(nodes, groups, rules)

    if args.subscription_refresh and args.input.startswith(('http://', 'https://')) and args.format == 'surge':
        nl = '\n'
        output = output.replace('[Proxy]' + nl, '[Proxy]' + nl + '#!include ' + args.input + nl, 1)

    if not args.output:
        args.output = auto_output_name(args, protos)
    with open(args.output, 'w', encoding='utf-8') as f:
        f.write(output)
    print(f'✅ 已写入: {args.output}')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
