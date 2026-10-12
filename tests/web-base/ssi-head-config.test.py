#!/usr/bin/env python3
"""Exercise startup configuration without starting nginx or a container."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPOSITORY = Path(__file__).resolve().parents[2]
STARTUP = REPOSITORY / 'web-base/scripts/startup/50-env-configure-nginx-ssi-head.sh'


class SsiHeadConfigurationTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix='ssi-head-test-')
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.nginx = self.root / 'nginx'
        self.cache = self.root / 'cache'
        self.script = self.root / 'configure.sh'
        # Isolate the script's fixed container paths; never touch local /etc.
        self.script.write_text(STARTUP.read_text()
                               .replace('/etc/nginx', str(self.nginx))
                               .replace('/tmp/ssi-head-cache', str(self.cache)))
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        chown = self.bin / 'chown'
        chown.write_text('#!/bin/sh\nexit 0\n')
        chown.chmod(0o755)

    def configure(self, **settings):
        environment = {key: value for key, value in os.environ.items()
                       if not key.startswith('NGINX_SSI_HEAD_')}
        environment.update(settings)
        environment['PATH'] = str(self.bin) + os.pathsep + environment['PATH']
        return subprocess.run(['sh', str(self.script)], env=environment,
                              capture_output=True, text=True, timeout=5)

    def read(self, relative):
        return (self.nginx / relative).read_text()

    def test_opt_out_removes_previously_generated_configuration(self):
        self.assertEqual(self.configure(NGINX_SSI_HEAD_URL='http://127.0.0.1/head').returncode, 0)
        self.assertEqual(self.configure().returncode, 0)
        self.assertNotIn('ssi on', self.read('snippets/ssi-head-html.conf'))
        self.assertFalse((self.nginx / 'http.d/generated-ssi-head-cache.conf').exists())
        self.assertFalse((self.nginx / 'site-mods-enabled.d/generated-ssi-head.conf').exists())

    def test_defaults_isolate_domains_and_do_not_cache_errors(self):
        url = 'https://api.example.test/head?source=web&language=en'
        self.assertEqual(self.configure(NGINX_SSI_HEAD_URL=url).returncode, 0)
        location = self.read('site-mods-enabled.d/generated-ssi-head.conf')
        self.assertIn(f'proxy_pass "{url}";', location)
        self.assertIn(f'proxy_cache_key "{url}|$host";', location)
        self.assertNotIn('$request_uri', location)
        self.assertIn('proxy_pass_request_headers off;', location)
        self.assertIn('proxy_set_header X-Forwarded-Host $host;', location)
        self.assertIn('proxy_ssl_verify on;', location)
        self.assertIn('proxy_cache_valid 200 1h;', location)
        self.assertIn('proxy_cache_background_update on;', location)
        self.assertIn('proxy_cache_use_stale updating;', location)
        self.assertIn('proxy_no_cache $ssi_head_do_not_cache;', location)
        cache = self.read('http.d/generated-ssi-head-cache.conf')
        self.assertIn('max_size=100m inactive=2h', cache)
        self.assertIn('keys_zone=ssi_head:1m', cache)
        html = self.read('snippets/ssi-head-html.conf')
        self.assertIn('etag off;', html)
        self.assertIn('if_modified_since off;', html)

    def test_endpoint_without_path_targets_upstream_root(self):
        result = self.configure(NGINX_SSI_HEAD_URL='https://127.0.0.1:8081')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('proxy_pass "https://127.0.0.1:8081/";',
                      self.read('site-mods-enabled.d/generated-ssi-head.conf'))

    def test_cache_limits_are_configurable(self):
        result = self.configure(NGINX_SSI_HEAD_URL='http://[::1]:8081/head',
                                NGINX_SSI_HEAD_CACHE_TTL='5s',
                                NGINX_SSI_HEAD_CACHE_INACTIVE='30m',
                                NGINX_SSI_HEAD_CACHE_MAX_SIZE='8m')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('proxy_cache_valid 200 5s;', self.read('site-mods-enabled.d/generated-ssi-head.conf'))
        self.assertIn('max_size=8m inactive=30m', self.read('http.d/generated-ssi-head-cache.conf'))

    def test_untrusted_configuration_is_rejected_before_writing(self):
        invalid = {
            'NGINX_SSI_HEAD_URL': [
                'ftp://api.example/head', 'http://user:password@api.example/head',
                'http://api.example/head#fragment', 'http://api.example/$host',
                'http://api.example/"; return 200; #',
                'http://api.example/head\nserver { listen 1234; }',
            ],
            'NGINX_SSI_HEAD_CACHE_TTL': ['0', '-1h', '1h; return 200;', '1h\n1d'],
            'NGINX_SSI_HEAD_CACHE_INACTIVE': ['0s', 'two hours', '2h\r\n1d'],
            'NGINX_SSI_HEAD_CACHE_MAX_SIZE': ['0', '-1m', '100m; server {}', '100m\n1g'],
        }
        for setting, values in invalid.items():
            for value in values:
                with self.subTest(setting=setting, value=value):
                    settings = {'NGINX_SSI_HEAD_URL': 'http://127.0.0.1/head', setting: value}
                    result = self.configure(**settings)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertFalse(self.nginx.exists())


if __name__ == '__main__':
    unittest.main()
