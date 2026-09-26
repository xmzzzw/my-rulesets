#!/usr/bin/env python3
import importlib.util
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('myrules_convert', ROOT / 'tools' / 'convert.py')
mod = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mod)


def node(name, proto='ss'):
    return {'name': name, 'proto': proto, 'line': f'{name} = {proto}, 127.0.0.1, 443'}


class SelfHostedPolicyTests(unittest.TestCase):
    def setUp(self):
        self.nodes = [
            node('DMIT | LAX | Snell', 'snell'),
            node('DMIT | LAX | HY2', 'hysteria2'),
            node('🇺🇸 US | 美国 01'),
            node('🇺🇸 US | 美国 02'),
            node('🇭🇰 HK | 香港 01'),
            node('🇭🇰 HK | 香港 02'),
            node('🇯🇵 JP | 日本 01'),
        ]

    def test_dmit_is_first_class_group(self):
        groups, by_country, dmit = mod.build_policy_groups(self.nodes)
        by_name = {g['name']: g for g in groups}

        self.assertEqual(dmit, ['DMIT | LAX | Snell', 'DMIT | LAX | HY2'])
        self.assertEqual(by_name['Proxies']['members'][0], mod.DMIT_GROUP)
        self.assertEqual(by_name['AI']['members'][0], mod.DMIT_GROUP)
        self.assertEqual(
            by_name[mod.DMIT_GROUP]['members'],
            [mod.DMIT_AUTO, 'DMIT | LAX | Snell', 'DMIT | LAX | HY2'],
        )
        self.assertEqual(
            by_name[mod.DMIT_AUTO]['members'],
            ['DMIT | LAX | Snell', 'DMIT | LAX | HY2'],
        )

    def test_dmit_never_enters_country_or_other(self):
        groups, by_country, _ = mod.build_policy_groups(self.nodes)
        flattened = [name for names in by_country.values() for name in names]
        self.assertNotIn('DMIT | LAX | Snell', flattened)
        self.assertNotIn('DMIT | LAX | HY2', flattened)
        self.assertEqual(by_country['🇺🇸 美国'], ['🇺🇸 US | 美国 01', '🇺🇸 US | 美国 02'])
        self.assertEqual(by_country['🌍 其他地区'], ['🇯🇵 JP | 日本 01'])

    def test_no_dmit_keeps_previous_shape(self):
        nodes = [
            node('🇺🇸 US | 美国 01'),
            node('🇺🇸 US | 美国 02'),
        ]
        groups, _, dmit = mod.build_policy_groups(nodes)
        names = [g['name'] for g in groups]
        self.assertEqual(dmit, [])
        self.assertNotIn(mod.DMIT_GROUP, names)
        self.assertEqual(groups[0]['members'], ['🇺🇸 美国'])
        ai = next(g for g in groups if g['name'] == 'AI')
        self.assertEqual(ai['members'][:2], ['Proxies', '🎯Direct'])


if __name__ == '__main__':
    unittest.main()
