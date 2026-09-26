#!/usr/bin/env python3
import importlib.util
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("convert", ROOT / "tools" / "convert.py")
mod = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(mod)


class SelfHostedPolicyTest(unittest.TestCase):
    def setUp(self):
        def node(name, proto="ss"):
            return {"name": name, "proto": proto, "line": f"{name} = {proto}, 127.0.0.1, 443"}

        self.self_nodes = [
            node("DMIT | LAX-01 | Snell", "snell"),
            node("DMIT | LAX-01 | HY2", "hysteria2"),
            node("DMIT | LAX-02 | Snell", "snell"),
            node("DMIT | LAX-02 | HY2", "hysteria2"),
            node("Lisa | LAX-01 | Snell", "snell"),
            node("Lisa | LAX-01 | HY2", "hysteria2"),
        ]
        self.nodes = self.self_nodes + [
            node("🇭🇰 HK | 香港 01"),
            node("🇭🇰 HK | 香港 02"),
            node("🇺🇸 US | 美国 01"),
            node("🇺🇸 US | 美国 02"),
            node("🇯🇵 JP | 日本 01"),
        ]

    def groups(self):
        groups, by_country, self_nodes = mod.build_policy_groups(self.nodes)
        return groups, {g["name"]: g for g in groups}, by_country, self_nodes

    def test_generic_self_hosted_parser(self):
        self.assertEqual(
            mod.parse_self_hosted_name("DMIT | LAX-01 | Snell")["group_name"],
            "🖥 DMIT · LAX-01",
        )
        self.assertEqual(
            mod.parse_self_hosted_name("Lisa | LAX-01 | HY2")["auto_name"],
            "🖥 Lisa · LAX-01-自动",
        )
        self.assertIsNone(mod.parse_self_hosted_name("🇺🇸 US | 美国 01"))
        self.assertIsNone(mod.parse_self_hosted_name("US | Premium | Node"))

    def test_frontend_group_shape(self):
        groups, g, _, self_nodes = self.groups()
        self.assertEqual(g["Proxies"]["members"][0], "🏠 自建节点")
        self.assertEqual(g["AI"]["members"][0], "🏠 自建节点")
        self.assertEqual(
            g["🏠 自建节点"]["members"],
            ["🏠 自建节点-自动", "🖥 DMIT · LAX-01", "🖥 DMIT · LAX-02", "🖥 Lisa · LAX-01"],
        )
        self.assertEqual(g["🏠 自建节点-自动"]["members"], self_nodes)
        self.assertEqual(
            g["🖥 DMIT · LAX-01"]["members"],
            ["🖥 DMIT · LAX-01-自动", "DMIT | LAX-01 | Snell", "DMIT | LAX-01 | HY2"],
        )
        self.assertEqual(
            g["🖥 DMIT · LAX-01-自动"]["members"],
            ["DMIT | LAX-01 | Snell", "DMIT | LAX-01 | HY2"],
        )

        names = [item["name"] for item in groups]
        final = names.index("✈️Final")
        self.assertEqual(
            names[final + 1: final + 9],
            [
                "🏠 自建节点",
                "🏠 自建节点-自动",
                "🖥 DMIT · LAX-01",
                "🖥 DMIT · LAX-01-自动",
                "🖥 DMIT · LAX-02",
                "🖥 DMIT · LAX-02-自动",
                "🖥 Lisa · LAX-01",
                "🖥 Lisa · LAX-01-自动",
            ],
        )

    def test_self_hosted_does_not_leak_to_country_groups(self):
        _, g, by_country, self_nodes = self.groups()
        self_names = set(self_nodes)
        for country_nodes in by_country.values():
            self.assertTrue(self_names.isdisjoint(country_nodes))
        self.assertTrue(self_names.isdisjoint(g["🇺🇸 美国"]["members"]))
        self.assertTrue(self_names.isdisjoint(g["🌍 其他地区"]["members"]))

    def test_no_self_hosted_preserves_country_only_structure(self):
        normal = [
            {"name": "🇭🇰 HK | 香港 01", "proto": "ss", "line": "a = ss, 1.1.1.1, 443"},
            {"name": "🇭🇰 HK | 香港 02", "proto": "ss", "line": "b = ss, 1.1.1.2, 443"},
        ]
        groups, _, self_nodes = mod.build_policy_groups(normal)
        self.assertEqual(self_nodes, [])
        self.assertEqual(groups[0]["members"][0], "🇭🇰 香港")
        self.assertNotIn("🏠 自建节点", [g["name"] for g in groups])


if __name__ == "__main__":
    unittest.main()
