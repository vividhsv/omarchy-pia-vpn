#!/usr/bin/env python3
"""Read WireGuard counters from sysfs for the Omarchy PIA plugin."""

import os
import sys

IFACE = "wgpia0"
BASE = f"/sys/class/net/{IFACE}/statistics"


def kv(key, value):
    text = "" if value is None else str(value)
    text = text.replace("\r", " ").replace("\n", " ").strip()
    print(f"{key}={text}")


def read_counter(name):
    path = os.path.join(BASE, name)
    try:
        with open(path, "r", encoding="ascii") as fh:
            return fh.read().strip()
    except OSError:
        return None


def main():
    rx = read_counter("rx_bytes")
    tx = read_counter("tx_bytes")
    if rx is None or tx is None:
        kv("ok", "false")
        kv("rx", "")
        kv("tx", "")
        return 0
    kv("ok", "true")
    kv("rx", rx)
    kv("tx", tx)
    return 0


if __name__ == "__main__":
    sys.exit(main())
