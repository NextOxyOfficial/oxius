from django.test import TestCase
from django.urls import reverse

from .models import AppVersionConfig


class AppVersionCheckTests(TestCase):
    def test_returns_optional_update_when_current_build_is_behind(self):
        AppVersionConfig.objects.create(
            platform="android",
            latest_version="8.0.32",
            latest_build=72,
            minimum_supported_version="8.0.10",
            minimum_supported_build=50,
            force_update=False,
            store_url="https://example.com/android",
        )

        response = self.client.get(
            reverse("app-version-check"),
            {"platform": "android", "version": "8.0.31", "build": "71"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["update_available"])
        self.assertFalse(response.json()["force_update"])

    def test_returns_force_update_when_current_build_is_below_minimum(self):
        AppVersionConfig.objects.create(
            platform="ios",
            latest_version="8.0.32",
            latest_build=72,
            minimum_supported_version="8.0.30",
            minimum_supported_build=70,
            force_update=False,
            store_url="https://example.com/ios",
        )

        response = self.client.get(
            reverse("app-version-check"),
            {"platform": "ios", "version": "8.0.29", "build": "69"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["update_available"])
        self.assertTrue(response.json()["force_update"])

    def test_returns_no_update_when_current_build_is_current(self):
        AppVersionConfig.objects.create(
            platform="ios",
            latest_version="8.0.32",
            latest_build=72,
            store_url="https://example.com/ios",
        )

        response = self.client.get(
            reverse("app-version-check"),
            {"platform": "ios", "version": "8.0.32", "build": "72"},
        )

        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.json()["update_available"])
        self.assertFalse(response.json()["force_update"])
