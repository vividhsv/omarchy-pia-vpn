#!/usr/bin/env python3
"""List piactl regions with best-effort map coordinates for the Omarchy plugin."""

import json
import os
import re
import shutil
import subprocess
import sys

# piactl region id → a GPS key in modernRegionMeta.gps (before normalize).
# Keep this small: suffix stripping handles -pf / -so / streaming-optimized.
REGION_ALIASES = {
    "albania": "al",
    "algeria": "dz",
    "andorra": "ad",
    "argentina": "ar",
    "armenia": "yerevan",
    "au-adelaide": "au-adelaide",
    "au-brisbane": "au-brisbane",
    "au-melbourne": "aus-melbourne",
    "au-perth": "aus-perth",
    "au-sydney": "aus",
    "australia-streaming-optimized": "au-australia",
    "bolivia": "bo-bolivia",
    "bosnia-and-herzegovina": "ba",
    "brazil": "br",
    "bulgaria": "sofia",
    "ca-montreal": "ca",
    "chile": "santiago",
    "colombia": "bogota",
    "costa-rica": "sanjose",
    "croatia": "zagreb",
    "czech-republic": "czech",
    "ecuador": "ec-ecuador",
    "es-madrid": "spain",
    "estonia": "ee",
    "fi-helsinki": "fi",
    "greece": "gr",
    "guatemala": "gt-guatemala",
    "hong-kong": "hk",
    "iceland": "is",
    "india": "in",
    "indonesia": "jakarta",
    "isle-of-man": "man",
    "israel": "israel",
    "it-milano": "italy",
    "it-streaming-optimized": "italy",
    "jp-tokyo": "japan",
    "jp-streaming-optimized": "japan",
    "dk-streaming-optimized": "denmark",
    "latvia": "lv",
    "lithuania": "lt",
    "luxembourg": "lu",
    "malaysia": "kualalumpur",
    "moldova": "md",
    "nepal": "np-nepal",
    "netherlands": "nl-amsterdam",
    "new-zealand": "nz",
    "north-macedonia": "mk",
    "norway": "no",
    "peru": "pe-peru",
    "portugal": "pt",
    "romania": "ro",
    "saudi-arabia": "saudiarabia",
    "se-stockholm": "sweden",
    "se-streaming-optimized": "sweden",
    "serbia": "rs",
    "singapore": "sg",
    "slovakia": "sk",
    "south-africa": "za",
    "south-korea": "kr-south-korea",
    "sri-lanka": "srilanka",
    "switzerland": "swiss",
    "turkey": "tr",
    "uk-london": "uk",
    "ukraine": "ua",
    "united-arab-emirates": "ae",
    "uruguay": "uy-uruguay",
    "us-east": "us-newjersey",
    "us-east-streaming-optimized": "us-streaming",
    "us-new-york": "us-new-york-city",
    "us-texas": "us-south-west",
    "us-west": "us-california",
    "us-west-streaming-optimized": "us-california",
}

_SUFFIXES = (
    "-streaming-optimized",
    "-streaming",
    "-pf",
    "-so",
)


def normalize_gps_key(value):
    text = str(value or "").lower().replace("_", "-")
    text = re.sub(r"[^a-z0-9-]+", "-", text)
    text = re.sub(r"-+", "-", text).strip("-")
    changed = True
    while changed and text:
        changed = False
        for suffix in _SUFFIXES:
            if text.endswith(suffix) and len(text) > len(suffix):
                text = text[: -len(suffix)].rstrip("-")
                changed = True
        if text.endswith("-2") and len(text) > 2:
            text = text[:-2].rstrip("-")
            changed = True
    return text


def parse_coord_pair(value):
    if isinstance(value, (list, tuple)) and len(value) >= 2:
        try:
            lat = float(value[0])
            lon = float(value[1])
        except (TypeError, ValueError):
            return None
        if -90 <= lat <= 90 and -180 <= lon <= 180:
            return (lat, lon)
    return None


def gps_index(gps):
    index = {}
    if not isinstance(gps, dict):
        return index
    for key, value in gps.items():
        pair = parse_coord_pair(value)
        if pair is None:
            continue
        original = str(key or "").lower().replace("_", "-")
        original = re.sub(r"[^a-z0-9-]+", "-", original)
        original = re.sub(r"-+", "-", original).strip("-")
        if original and original not in index:
            index[original] = pair
        normalized = normalize_gps_key(key)
        if normalized and normalized not in index:
            index[normalized] = pair
    return index


def region_candidates(region_id, aliases=None):
    alias_map = REGION_ALIASES if aliases is None else aliases
    rid = str(region_id or "").strip()
    if rid == "" or rid == "auto":
        return []
    names = [rid]
    mapped = alias_map.get(rid)
    if mapped:
        names.append(mapped)
    normalized = normalize_gps_key(rid)
    if normalized and normalized not in names:
        names.append(normalized)
    mapped_norm = alias_map.get(normalized) if normalized else None
    if mapped_norm:
        names.append(mapped_norm)
    if normalized.endswith("-streaming-optimized"):
        parent = normalized[: -len("-streaming-optimized")].rstrip("-")
        if parent:
            names.append(parent)
            parent_alias = alias_map.get(parent)
            if parent_alias:
                names.append(parent_alias)
    if rid.startswith("us-") and not rid.endswith("-city"):
        names.append(rid + "-city")
        names.append(normalize_gps_key(rid + "-city"))
    seen = []
    for name in names:
        key = normalize_gps_key(name)
        if key and key not in seen:
            seen.append(key)
        raw = str(name or "").lower().replace("_", "-")
        raw = re.sub(r"[^a-z0-9-]+", "-", raw)
        raw = re.sub(r"-+", "-", raw).strip("-")
        if raw and raw not in seen:
            seen.append(raw)
    return seen


def region_coords(region_id, gps, aliases=None):
    if str(region_id or "").strip() == "auto":
        return None
    index = gps if isinstance(gps, dict) and gps and isinstance(next(iter(gps.values()), None), tuple) else gps_index(gps)
    for key in region_candidates(region_id, aliases):
        pair = index.get(key)
        if pair:
            return {"lat": pair[0], "lon": pair[1]}
    return None


MAP_SOUTH_LAT = -60.0


def map_south_lat():
    return MAP_SOUTH_LAT


def map_aspect():
    return (90.0 - MAP_SOUTH_LAT) / 360.0


def project_equirectangular(lat, lon, width, height):
    try:
        lat_n = float(lat)
        lon_n = float(lon)
        width_n = float(width)
        height_n = float(height)
    except (TypeError, ValueError):
        return None
    if width_n <= 0 or height_n <= 0:
        return None
    south = MAP_SOUTH_LAT
    span = 90.0 - south
    if not (south <= lat_n <= 90 and -180 <= lon_n <= 180):
        return None
    return {
        "x": (lon_n + 180.0) / 360.0 * width_n,
        "y": (90.0 - lat_n) / span * height_n,
    }


def find_piactl(explicit=None):
    if explicit:
        return explicit
    found = shutil.which("piactl")
    if found:
        return found
    for candidate in ("/opt/piavpn/bin/piactl", "/usr/local/bin/piactl"):
        if os.access(candidate, os.X_OK):
            return candidate
    return None


def run(argv, timeout=8):
    try:
        result = subprocess.run(
            argv,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        stdout = (result.stdout or "").strip()
        stderr = (result.stderr or "").strip()
        return result.returncode, stdout, stderr
    except subprocess.TimeoutExpired:
        return 1, "", "timeout"
    except OSError as exc:
        return 1, "", str(exc)


def kv(key, value):
    text = "" if value is None else str(value)
    text = text.replace("\r", " ").replace("\n", " ").strip()
    print(f"{key}={text}")


def load_gps(piactl):
    code, stdout, _stderr = run([piactl, "-u", "dump", "daemon-data"], timeout=12)
    if code != 0 or not stdout:
        return {}
    try:
        data = json.loads(stdout)
    except json.JSONDecodeError:
        return {}
    meta = data.get("modernRegionMeta") if isinstance(data, dict) else None
    gps = meta.get("gps") if isinstance(meta, dict) else None
    return gps if isinstance(gps, dict) else {}


def region_ids(piactl):
    code, stdout, _stderr = run([piactl, "get", "regions"])
    if code != 0:
        return None
    ids = []
    for line in stdout.splitlines():
        value = line.strip()
        if value:
            ids.append(value)
    return ids


def main():
    explicit = sys.argv[1] if len(sys.argv) > 1 else None
    piactl = find_piactl(explicit)
    if not piactl:
        return 1
    ids = region_ids(piactl)
    if ids is None:
        return 1
    index = gps_index(load_gps(piactl))
    first = True
    for region_id in ids:
        if not first:
            print()
        first = False
        kv("id", region_id)
        coords = region_coords(region_id, index)
        if coords:
            kv("lat", coords["lat"])
            kv("lon", coords["lon"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
