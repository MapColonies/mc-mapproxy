# This file is part of the MapProxy project.
# Copyright (C) 2017 Omniscale <http://omniscale.de>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ── MapColonies patch ─────────────────────────────────────────────────────────
# Replaces the upstream MapProxy redis.py with a fault-tolerant version:
#
#  • Configurable socket / connection timeouts via env vars so a slow or
#    unreachable Redis instance never blocks a tile request indefinitely.
#  • All cache operations (is_cached, store_tile, load_tile) catch
#    redis.exceptions.ConnectionError and any unexpected Exception and return
#    False (cache-miss) instead of raising — MapProxy then falls back to the
#    next configured source transparently.
#  • Optional TLS support via REDIS_TLS / SSL_CERTS_REQS env vars.
#
# Env vars (all optional — the defaults keep the original behaviour):
#   SOCKET_TIMEOUT_SECONDS            – per-operation timeout       (default: 0.1 s)
#   SOCKET_CONNECTION_TIMEOUT_SECONDS – connect timeout             (default: 0.1 s)
#   REDIS_POOL_TIMEOUT                – max wait for a free conn    (default: 0.1 s)
#   REDIS_TLS                         – enable TLS                  (default: false)
#   SSL_CERT_REQS                     – ssl_cert_reqs value         (default: required)
# ─────────────────────────────────────────────────────────────────────────────

from __future__ import absolute_import
import datetime
import hashlib
import os
import time

from io import BytesIO

from mapproxy.image import ImageSource
from mapproxy.cache.base import (
    TileCacheBase,
    tile_buffer,
)

try:
    import redis
except ImportError:
    redis = None

import logging
log = logging.getLogger(__name__)


class RedisCache(TileCacheBase):
    def __init__(
            self, host, port, prefix, ttl=0, db=0, username=None, password=None,
            coverage=None, ssl_certfile=None, ssl_keyfile=None, ssl_ca_certs=None):
        super(RedisCache, self).__init__(coverage)

        if redis is None:
            raise ImportError("Redis backend requires 'redis' package.")

        self.ssl_certfile = ssl_certfile
        self.ssl_keyfile = ssl_keyfile
        self.ssl_ca_certs = ssl_ca_certs

        self.prefix = prefix
        md5 = hashlib.new('md5', (host + str(port) + prefix + str(db)).encode('utf-8'), usedforsecurity=False)
        self.lock_cache_id = 'redis-' + md5.hexdigest()
        self.ttl = ttl

        # Configurable timeouts — short defaults so a dead Redis never stalls requests.
        # Override via SOCKET_TIMEOUT_SECONDS / SOCKET_CONNECTION_TIMEOUT_SECONDS env vars.
        self.socket_timeout = float(os.environ.get('SOCKET_TIMEOUT_SECONDS', 0.1))
        self.socket_connection_timeout = float(
            os.environ.get('SOCKET_CONNECTION_TIMEOUT_SECONDS', 0.1)
        )

        # Max time (s) to wait for a free connection from the pool before giving up.
        self.pool_timeout = float(os.environ.get('REDIS_POOL_TIMEOUT', 0.1))

        # SSL: enabled when cert+key files are provided (upstream behaviour), or
        # when REDIS_TLS=true is set (e.g. for servers that don't require client certs).
        ssl_enabled = all([self.ssl_certfile, self.ssl_keyfile]) or get_redis_variable("REDIS_TLS")
        _ssl_certfile = self.ssl_certfile if ssl_enabled else None
        _ssl_keyfile = self.ssl_keyfile if ssl_enabled else None
        _ssl_ca_certs = self.ssl_ca_certs if ssl_enabled and self.ssl_ca_certs else None
        # ssl_cert_reqs: controls server-cert verification ('required', 'optional', 'none').
        # Defaults to 'required'; set SSL_CERT_REQS=none to disable (e.g. self-signed certs).
        _ssl_cert_reqs = os.environ.get('SSL_CERT_REQS', 'required') if ssl_enabled else None

        pool = redis.ConnectionPool(
            host=host,
            port=port,
            db=db,
            username=username,
            password=password,
            socket_timeout=self.socket_timeout,
            socket_connect_timeout=self.socket_connection_timeout,
            timeout=self.pool_timeout,
            ssl=ssl_enabled,
            ssl_certfile=_ssl_certfile,
            ssl_keyfile=_ssl_keyfile,
            ssl_ca_certs=_ssl_ca_certs,
            ssl_cert_reqs=_ssl_cert_reqs,
        )
        self.r = redis.StrictRedis(connection_pool=pool)

    def _key(self, tile):
        x, y, z = tile.coord
        return self.prefix + '-%d-%d-%d' % (z, x, y)

    def is_cached(self, tile, dimensions=None):
        if tile.coord is None or tile.source:
            return True
        key = self._key(tile)

        try:
            log.debug('exists_key, key: %s' % key)
            return self.r.exists(key)
        except redis.exceptions.ConnectionError as e:
            log.error('Error during connection %s' % e)
            return False
        except Exception as e:
            log.error('REDIS:exists_key error  %s' % e)
            return False

    def store_tile(self, tile, dimensions=None):
        if tile.stored:
            return True
        key = self._key(tile)

        with tile_buffer(tile) as buf:
            data = buf.read()

        try:
            log.debug('store_key, key: %s' % key)
            r = self.r.set(key, data)
        except redis.exceptions.ConnectionError as e:
            log.error('Error during connection %s' % e)
            return False
        except Exception as e:
            log.error('REDIS:store_key error  %s' % e)
            return False

        if self.ttl:
            # use ms expire times for unit-tests
            self.r.pexpire(key, int(self.ttl * 1000))
        return r

    def load_tile(self, tile, with_metadata=False, dimensions=None):
        if tile.source or tile.coord is None:
            return True
        key = self._key(tile)

        try:
            log.debug('get_key, key: %s' % key)
            tile_data = self.r.get(key)
            if tile_data:
                tile.source = ImageSource(BytesIO(tile_data))
                return True
            return False
        except redis.exceptions.ConnectionError as e:
            log.error('Error during connection %s' % e)
            return False
        except Exception as e:
            log.error('REDIS:get_key error  %s' % e)
            return False

    def load_tile_metadata(self, tile, dimensions=None):
        if tile.timestamp:
            return
        pipe = self.r.pipeline()
        pipe.ttl(self._key(tile))
        pipe.memory_usage(self._key(tile))
        pipe_res = pipe.execute()
        tile.timestamp = (
            time.mktime(datetime.datetime.now().timetuple()) - self.ttl - int(pipe_res[0])
        )
        tile.size = pipe_res[1]

    def remove_tile(self, tile, dimensions=None):
        if tile.coord is None:
            return True
        key = self._key(tile)
        self.r.delete(key)
        return True


def get_redis_variable(name):
    env_var = os.environ.get(name, "false")
    if env_var.lower().strip() in ("true"):
        return True
    else:
        return False
