#!/usr/bin/env python3
"""
my-rulesets 配置转换工具
========================
灵活处理「机场订阅 → 自定义配置」的各种转换场景。

支持:
- 输入: Surge(.conf) / Clash(.yaml) / 订阅URL / 节点列表
- 协议: ss / trojan / anytls / vmess / vless / hysteria2 / ...
- 输出: Surge配置 / Clash配置 / 覆写脚本数据
- 自动: 国家识别、单节点国家合并、流量伪节点、协议标注

用法:
  python3 convert.py --input <文件或URL> --format <surge|clash> [选项]
"""
import re
import sys
import os
import json
import argparse
from collections import defaultdict

# ============ 国家识别 ============
# 国家代码 → emoji + 中文名
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

# emoji → 中文名
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

# 中文国家名 → emoji+名
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

def detect_country(node_name):
    """自动识别节点所属国家（灵活匹配多种命名格式）"""
    # 1. 尝试 emoji 匹配（如 🇭🇰 HK | 香港 01）
    for emoji, cn in EMOJI_MAP.items():
        if emoji in node_name:
            return f"{emoji} {cn}"
    # 2. 尝试国家代码（HK/SG/JP/...）
    for code, full in COUNTRY_MAP.items():
        # 匹配 "HK" 作为独立单词或 "| HK" 格式
        if re.search(rf'\b{code}\b', node_name) or f'|{code}' in node_name or f'{code}|' in node_name:
            return full
    # 3. 尝试中文名
    for cn, full in CN_NAME_MAP.items():
        if cn in node_name:
            return full
    # 4. 归为其他
    return '🌍 其他地区'

# ============ 协议识别 ============
PROTOCOLS = ['ss', 'trojan', 'anytls', 'vmess', 'vless', 'hysteria2', 'hysteria', 'tuic', 'wireguard', 'snell', 'http', 'socks5']

def detect_protocol(line):
    """识别节点行使用的协议"""
    for proto in PROTOCOLS:
        if re.search(rf' = {proto}, ', line) or f'type: {proto}' in line:
            return proto
    return None

def detect_node_protocols(lines):
    """统计所有节点协议分布"""
    protos = defaultdict(int)
    for line in lines:
        p = detect_protocol(line)
        if p:
            protos[p] += 1
    return dict(protos)

# ============ 输入解析 ============
def read_input(path_or_url):
    """读取输入（文件或 URL），支持自动检测"""
    if path_or_url.startswith('http://') or path_or_url.startswith('https://'):
        import urllib.request
        # 尝试直连（绕过代理，机场常限制代理 IP）
        try:
            req = urllib.request.Request(path_or_url, headers={'User-Agent': 'ClashForWindows/0.20.39'})
            proxy_handler = urllib.request.ProxyHandler({})
            opener = urllib.request.build_opener(proxy_handler)
            with opener.open(req, timeout=30) as r:
                return r.read().decode('utf-8', errors='replace')
        except Exception as e:
            # 回退到默认方式
            with urllib.request.urlopen(path_or_url, timeout=30) as r:
                return r.read().decode('utf-8', errors='replace')
    else:
        with open(path_or_url, encoding='utf-8') as f:
            return f.read()

def parse_proxies(content):
    """从配置内容提取节点列表 [(name, proto, details)]"""
    nodes = []
    # Surge 格式: name = proto, server, port, params
    for line in content.splitlines():
        m = re.match(r'^(.+?) = (\w+), (.+)$', line.strip())
        if m:
            name, proto, rest = m.groups()
            if proto in PROTOCOLS:
                nodes.append({'name': name.strip(), 'proto': proto, 'line': line})
    return nodes

def is_clash_yaml(content):
    """判断是否是 Clash YAML 格式"""
    return 'proxies:' in content and ('type: ss' in content or 'type: trojan' in content)

def is_surge_conf(content):
    """判断是否是 Surge 格式"""
    return '[Proxy]' in content and ' = ss, ' in content or '[Proxy]' in content and ' = trojan, ' in content

# ============ 策略组构建 ============
def build_policy_groups(nodes, single_node_merge=True):
    """构建策略组（国家分组 + 自动选择 + 应用组），单节点国家合并"""
    # 按国家归类
    by_country = defaultdict(list)
    for node in nodes:
        country = detect_country(node['name'])
        by_country[country].append(node['name'])
    
    # 单节点国家合并（≤1 节点 → 其他地区）
    if single_node_merge:
        singletons = [c for c, names in by_country.items() if len(names) <= 1]
        for c in singletons:
            by_country['🌍 其他地区'].extend(by_country[c])
            del by_country[c]
    
    # 排序：国家按节点数降序（节点最多的排最前），🌍 其他地区恒在最后
    countries = sorted(
        (c for c in by_country if c != '🌍 其他地区'),
        key=lambda x: -len(by_country[x])
    ) + ['🌍 其他地区']
    
    # 构建策略组
    groups = []
    # 顶层 Proxies
    groups.append({'name': 'Proxies', 'type': 'select', 'members': countries})
    
    # 应用策略组
    app_groups = ['AI', 'Netflix', 'HBO', 'DisneyPlus', 'YouTube', 'Bahamut', 'Bilibili',
                  'MyTVSuper', 'Telegram', 'Crypto', 'Steam', 'Epic', 'Xbox', 'PlayStation',
                  'Microsoft', 'Scholar', 'Apple', 'Google', 'Tiktok']
    for app in app_groups:
        groups.append({'name': app, 'type': 'select', 'members': ['Proxies', '🎯Direct'] + countries})
    
    # 直连 + Final
    groups.append({'name': '🎯Direct', 'type': 'select', 'members': ['DIRECT', 'Proxies']})
    groups.append({'name': '✈️Final', 'type': 'select', 'members': ['Proxies', '🎯Direct'] + countries})
    
    # 国家分组 + 自动选择（放 Final 后面）
    for c in countries:
        names = by_country[c]
        auto = f"{c}-自动"
        groups.append({'name': c, 'type': 'select', 'members': [auto] + names})
        groups.append({'name': auto, 'type': 'url-test', 'members': names,
                       'url': 'http://www.gstatic.com/generate_204', 'interval': 300, 'tolerance': 50})
    
    return groups, by_country

# ============ 输出 Surge ============
def to_surge(nodes, groups, rules, general_sections=None):
    """生成 Surge 配置"""
    out = []
    if general_sections:
        out.append(general_sections)
    out.append("[Proxy]")
    for n in nodes:
        out.append(n['line'])
    out.append("")
    out.append("[Proxy Group]")
    for g in groups:
        if g['type'] == 'select':
            out.append(f"{g['name']} = select, " + ", ".join(g['members']))
        elif g['type'] == 'url-test':
            out.append(f"{g['name']} = url-test, " + ", ".join(g['members']) +
                       f", url={g['url']}, interval={g['interval']}, tolerance={g['tolerance']}")
    out.append("")
    out.append("[Rule]")
    for r in rules:
        out.append(r)
    return "\n".join(out)

def auto_output_name(args, protos):
    """按「机场名称_协议_代理终端_MyRules.<ext>」生成输出文件名。

    - 机场名称：从订阅 URL 的 filename 参数 / host 推断；无则用 'MyAirport'
    - 协议：--protocol 指定，否则取节点中占比最大的协议
    - 代理终端：args.format（surge/clash → Surge/Clash）
    - 规则名：固定 MyRules
    - 扩展名：surge → .conf，clash → .yaml
    """
    # 机场名：filename 参数取首段（CreamData_Anytls_Clash.yaml → CreamData）
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

    # 协议
    proto = args.protocol
    if not proto and protos:
        proto = max(protos.items(), key=lambda x: x[1])[0]

    # 终端 + 扩展名
    fmt = args.format if args.format in ('surge', 'clash') else 'clash'
    term = 'Surge' if fmt == 'surge' else 'Clash'
    ext = 'conf' if fmt == 'surge' else 'yaml'

    return f"{name}_{proto}_{term}_MyRules.{ext}"


# ============ 主入口 ============
def main():
    parser = argparse.ArgumentParser(description='my-rulesets 配置转换工具')
    parser.add_argument('--input', required=True, help='输入文件或订阅URL')
    parser.add_argument('--format', choices=['surge', 'clash', 'auto'], default='auto',
                        help='输出格式（默认 auto 自动检测输入格式）')
    parser.add_argument('--no-merge-single', action='store_true',
                        help='不合并单节点国家（默认合并到其他地区）')
    parser.add_argument('--subscription-refresh', action='store_true',
                        help='Surge输出时 [Proxy] 段用 #!include 保留订阅刷新')
    parser.add_argument('--output', help='输出文件路径')
    parser.add_argument('--protocol', help='强制指定协议标注（如 ss/trojan/anytls）')
    args = parser.parse_args()
    
    # 读取输入
    content = read_input(args.input)
    
    # 解析节点
    nodes = parse_proxies(content)
    if not nodes:
        print(f"⚠️ 未识别到节点。输入可能不是标准格式，前 200 字符:\n{content[:200]}")
        return
    
    # 协议统计
    protos = detect_node_protocols([n['line'] for n in nodes])
    print(f"✅ 识别到 {len(nodes)} 个节点，协议分布: {protos}")
    
    # 构建策略组
    groups, by_country = build_policy_groups(nodes, single_node_merge=not args.no_merge_single)
    print(f"✅ 策略组: {len(groups)} 个")
    print(f"   国家分组: {len(by_country)} 个")
    for c, names in sorted(by_country.items(), key=lambda x: -len(x[1])):
        print(f"     {c}: {len(names)}")
    
    # 构建规则
    rules = []
    RULE_BASE = "https://raw.githubusercontent.com/xmzzzw/my-rulesets/main"
    ruleset_map = [
        ("nexitallyy_Extra_CN_3.list", "🎯Direct"), ("blackmatrix7_GlobalScholar.list", "Scholar"),
        ("blackmatrix7_myTVSUPER.list", "MyTVSuper"), ("nexitallyy_Extra_Crypto.list", "Crypto"),
        ("nexitallyy_Extra_AI.list", "AI"), ("blackmatrix7_Google.list", "Google"),
        ("ACL4SSR_YouTube.list", "YouTube"), ("blackmatrix7_GameDownload.list", "🎯Direct"),
        ("HotKids_Netflix.list", "Netflix"), ("ACL4SSR_Telegram.list", "Telegram"),
        ("blackmatrix7_Steam.list", "Steam"), ("blackmatrix7_Epic.list", "Epic"),
        ("blackmatrix7_Xbox.list", "Xbox"), ("blackmatrix7_PlayStation.list", "PlayStation"),
        ("HotKids_HBO_Max.list", "HBO"), ("blackmatrix7_HBOUSA.list", "HBO"),
        ("blackmatrix7_HBOHK.list", "HBO"), ("naiixi_DisneyPlus.list", "DisneyPlus"),
        ("ACL4SSR_Bahamut.list", "Bahamut"), ("HotKids_Bilibili.list", "Bilibili"),
        ("ACL4SSR_Microsoft.list", "Microsoft"), ("ACL4SSR_Apple.list", "Apple"),
        ("blackmatrix7_TikTok.list", "Tiktok"), ("ACL4SSR_ProxyLite.list", "Proxies"),
        ("blackmatrix7_Facebook.list", "Proxies"), ("nexitallyy_Extra_Proxies.list", "Proxies"),
        ("blackmatrix7_Twitter.list", "Proxies"), ("naiixi_Extra_CN.list", "🎯Direct"),
        ("naiixi_Extra_CN_2.list", "🎯Direct"), ("blackmatrix7_WeChat.list", "🎯Direct"),
    ]
    for file, policy in ruleset_map:
        rules.append(f"RULE-SET,{RULE_BASE}/{file},{policy},update-interval=86400")
    rules.append("GEOIP,CN,🎯Direct")
    rules.append("FINAL,✈️Final")
    
    # 输出
    if args.format == 'auto':
        args.format = 'surge' if is_surge_conf(content) else 'clash'

    if args.format == 'clash':
        output = to_clash(nodes, groups, rules)
    else:
        output = to_surge(nodes, groups, rules)

    # 订阅刷新：如果输入是 URL 且开启选项，用 #!include 替换 [Proxy] 段
    if args.subscription_refresh and (args.input.startswith('http')):
        nl = chr(10)
        output = output.replace("[Proxy]" + nl, "[Proxy]" + nl + "#!include " + args.input + nl, 1)

    # 输出路径：未指定时按「机场名称_协议_代理终端_MyRules.<ext>」自动命名
    if not args.output:
        args.output = auto_output_name(args, protos)

    with open(args.output, 'w', encoding='utf-8') as f:
        f.write(output)
    print(f"✅ 已写入: {args.output}")

if __name__ == '__main__':
    main()

# ============ Clash YAML 输出 ============
def to_clash(nodes, groups, rules, rule_providers=None):
    """生成 Clash YAML 配置（mihomo 兼容）"""
    import yaml
    config = {
        'mixed-port': 7890, 'allow-lan': False, 'mode': 'rule',
        'log-level': 'warning', 'ipv6': True,
        'dns': {
            'enable': True, 'enhanced-mode': 'fake-ip',
            'fake-ip-range': '198.18.0.1/16',
            'fake-ip-filter': ['*.lan', '+.local', '+.msftconnecttest.com', '+.msftncsi.com'],
            'default-nameserver': ['223.5.5.5', '119.29.29.29'],
            'nameserver': ['https://223.5.5.5/dns-query', 'https://doh.pub/dns-query'],
            'fallback': ['https://1.1.1.1/dns-query', 'https://dns.google/dns-query'],
            'fallback-filter': {'geoip': True, 'geoip-code': 'CN'},
        },
        'proxies': [], 'proxy-groups': [], 'rule-providers': {}, 'rules': [],
    }
    
    # proxies（转换协议格式）
    for n in nodes:
        # 从 Surge 行解析
        line = n['line']
        parts = [p.strip() for p in line.split(',')]
        name = n['name']
        proto = n['proto']
        server = parts[1]
        port = int(parts[2])
        params = {}
        for p in parts[3:]:
            if '=' in p:
                k, v = p.split('=', 1)
                params[k.strip()] = v.strip()
        
        proxy = {'name': name, 'type': proto, 'server': server, 'port': port}
        if proto == 'ss':
            proxy['cipher'] = params.get('encrypt-method', 'aes-256-gcm')
            proxy['password'] = params.get('password', '')
            proxy['udp'] = params.get('udp-relay', 'true').lower() == 'true'
            if params.get('obfs') == 'http':
                proxy['plugin'] = 'obfs'
                proxy['plugin-opts'] = {'mode': 'http', 'host': params.get('obfs-host', '')}
        elif proto == 'trojan':
            proxy['password'] = params.get('password', '')
            if 'sni' in params: proxy['sni'] = params['sni']
            proxy['skip-cert-verify'] = params.get('skip-cert-verify', 'false').lower() == 'true'
            proxy['udp'] = params.get('udp-relay', 'true').lower() == 'true'
        elif proto == 'anytls':
            proxy['password'] = params.get('password', '')
            if 'sni' in params: proxy['sni'] = params['sni']
            proxy['skip-cert-verify'] = params.get('skip-cert-verify', 'false').lower() == 'true'
            proxy['udp'] = params.get('udp-relay', 'true').lower() == 'true'
        elif proto == 'vmess':
            proxy['uuid'] = params.get('uuid', '')
            proxy['alterId'] = int(params.get('alterId', '0') or '0')
            proxy['cipher'] = params.get('encrypt-method', 'auto')
            proxy['udp'] = True
        config['proxies'].append(proxy)
    
    # proxy-groups
    for g in groups:
        group = {'name': g['name'], 'type': g['type'], 'proxies': g['members']}
        if g['type'] == 'url-test':
            group['url'] = g.get('url', 'http://www.gstatic.com/generate_204')
            group['interval'] = int(g.get('interval', 300))
            if 'tolerance' in g:
                group['tolerance'] = int(g['tolerance'])
        config['proxy-groups'].append(group)
    
    # rule-providers（引用 clash/ 规则集）
    RULE_BASE = "https://raw.githubusercontent.com/xmzzzw/my-rulesets/main/clash/"
    ruleset_files = [
        ("nexitallyy_Extra_CN_3.list", "🎯Direct"), ("blackmatrix7_GlobalScholar.list", "Scholar"),
        ("blackmatrix7_myTVSUPER.list", "MyTVSuper"), ("nexitallyy_Extra_Crypto.list", "Crypto"),
        ("nexitallyy_Extra_AI.list", "AI"), ("blackmatrix7_Google.list", "Google"),
        ("ACL4SSR_YouTube.list", "YouTube"), ("blackmatrix7_GameDownload.list", "🎯Direct"),
        ("ACL4SSR_LocalAreaNetwork.list", "🎯Direct"), ("ACL4SSR_ChinaCompanyIp.list", "🎯Direct"),
        ("HotKids_Netflix.list", "Netflix"), ("ACL4SSR_Telegram.list", "Telegram"),
        ("blackmatrix7_Steam.list", "Steam"), ("blackmatrix7_Epic.list", "Epic"),
        ("blackmatrix7_Xbox.list", "Xbox"), ("blackmatrix7_PlayStation.list", "PlayStation"),
        ("HotKids_HBO_Max.list", "HBO"), ("blackmatrix7_HBOUSA.list", "HBO"),
        ("blackmatrix7_HBOHK.list", "HBO"), ("naiixi_DisneyPlus.list", "DisneyPlus"),
        ("ACL4SSR_Bahamut.list", "Bahamut"), ("HotKids_Bilibili.list", "Bilibili"),
        ("ACL4SSR_Microsoft.list", "Microsoft"), ("ACL4SSR_Apple.list", "Apple"),
        ("blackmatrix7_TikTok.list", "Tiktok"), ("ACL4SSR_ProxyLite.list", "Proxies"),
        ("blackmatrix7_Facebook.list", "Proxies"), ("nexitallyy_Extra_Proxies.list", "Proxies"),
        ("blackmatrix7_Twitter.list", "Proxies"), ("naiixi_Extra_CN.list", "🎯Direct"),
        ("naiixi_Extra_CN_2.list", "🎯Direct"), ("blackmatrix7_WeChat.list", "🎯Direct"),
    ]
    for i, (file, policy) in enumerate(ruleset_files):
        pid = f"provider_{i}"
        config['rule-providers'][pid] = {
            'type': 'http', 'behavior': 'classical', 'format': 'text',
            'url': RULE_BASE + file, 'path': f"./providers/{file}", 'interval': 86400,
        }
        config['rules'].append(f"RULE-SET,{pid},{policy}")
    
    config['rules'].append('GEOIP,CN,🎯Direct,no-resolve')
    config['rules'].append('MATCH,✈️Final')
    
    return yaml.dump(config, allow_unicode=True, sort_keys=False, default_flow_style=False)
