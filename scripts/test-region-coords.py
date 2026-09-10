#!/usr/bin/env python3
"""Fixture tests for PIA region coordinate resolution (no live daemon dump)."""

import importlib.machinery
import importlib.util
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
SCRIPT = os.path.join(HERE, "pia-regions.sh")

loader = importlib.machinery.SourceFileLoader("pia_regions", SCRIPT)
spec = importlib.util.spec_from_loader(loader.name, loader)
regions = importlib.util.module_from_spec(spec)
loader.exec_module(regions)

# Invented keys only — do not copy PIA's live GPS table into the repo.
GPS = {
    "sg": ["1.29", "103.85"],
    "uk": ["51.50", "-0.12"],
    "us_north_carolina-pf": ["35.55", "-79.38"],
    "us_new_york_city": ["40.71", "-74.00"],
    "nl_amsterdam": ["52.37", "4.90"],
    "fr-so": ["48.85", "2.35"],
    "italy": ["45.47", "9.19"],
    "missing-place": ["91.00", "0.00"],
}


class RegionCoordTests(unittest.TestCase):
    def test_exact_city_match(self):
        coords = regions.region_coords("netherlands", GPS)
        self.assertIsNotNone(coords)
        self.assertAlmostEqual(coords["lat"], 52.37, places=2)
        self.assertAlmostEqual(coords["lon"], 4.90, places=2)

    def test_us_state_pf_suffix(self):
        coords = regions.region_coords("us-north-carolina", GPS)
        self.assertIsNotNone(coords)
        self.assertAlmostEqual(coords["lat"], 35.55, places=2)

    def test_singapore_alias(self):
        coords = regions.region_coords("singapore", GPS)
        self.assertIsNotNone(coords)
        self.assertAlmostEqual(coords["lon"], 103.85, places=2)

    def test_uk_london_alias(self):
        coords = regions.region_coords("uk-london", GPS)
        self.assertIsNotNone(coords)
        self.assertAlmostEqual(coords["lat"], 51.50, places=2)

    def test_auto_has_no_coords(self):
        self.assertIsNone(regions.region_coords("auto", GPS))
        self.assertIsNone(regions.region_coords("auto", {}))

    def test_streaming_optimized_parent(self):
        coords = regions.region_coords("fr-streaming-optimized", GPS)
        self.assertIsNotNone(coords)
        self.assertAlmostEqual(coords["lat"], 48.85, places=2)

    def test_streaming_alias_to_city(self):
        coords = regions.region_coords("it-streaming-optimized", GPS)
        self.assertIsNotNone(coords)
        self.assertAlmostEqual(coords["lat"], 45.47, places=2)

    def test_new_york_city_alias(self):
        coords = regions.region_coords("us-new-york", GPS)
        self.assertIsNotNone(coords)
        self.assertAlmostEqual(coords["lat"], 40.71, places=2)

    def test_missing_region(self):
        self.assertIsNone(regions.region_coords("atlantis", GPS))

    def test_invalid_coord_pair_ignored(self):
        self.assertIsNone(regions.region_coords("missing-place", GPS))

    def test_projection_origin(self):
        point = regions.project_equirectangular(0, 0, 360, 150)
        self.assertAlmostEqual(point["x"], 180)
        self.assertAlmostEqual(point["y"], 90)

    def test_projection_corners(self):
        nw = regions.project_equirectangular(90, -180, 360, 150)
        se = regions.project_equirectangular(-60, 180, 360, 150)
        self.assertAlmostEqual(nw["x"], 0)
        self.assertAlmostEqual(nw["y"], 0)
        self.assertAlmostEqual(se["x"], 360)
        self.assertAlmostEqual(se["y"], 150)

    def test_projection_rejects_antarctica(self):
        self.assertIsNone(regions.project_equirectangular(-75, 0, 360, 150))

    def test_projection_rejects_bad_input(self):
        self.assertIsNone(regions.project_equirectangular(91, 0, 100, 50))
        self.assertIsNone(regions.project_equirectangular(0, 0, 0, 50))


if __name__ == "__main__":
    result = unittest.main(verbosity=2, exit=False)
    sys.exit(0 if result.result.wasSuccessful() else 1)
