# Changelog

## [6.1.0](https://github.com/MapColonies/mc-mapproxy/compare/v6.0.1...v6.1.0) (2026-07-13)


### Features

* add celery support to Dockerfile and enhance logging in uwsgi configuration ([3edfe42](https://github.com/MapColonies/mc-mapproxy/commit/3edfe4225dc9e547c8f7be3556277b8132fc434f))
* add demo location block to nginx configuration for WMTS requests ([4d34447](https://github.com/MapColonies/mc-mapproxy/commit/4d34447ff7745f882e6512699fb333585fec256d))
* add nginx version 2.1.5 binary to helm charts ([8a9b7e2](https://github.com/MapColonies/mc-mapproxy/commit/8a9b7e22e2485d00c86ddcbf9c1233c6a0790f60))
* add Redis health check interval and S3 configuration options to values.yaml ([5363365](https://github.com/MapColonies/mc-mapproxy/commit/53633658f1785881002ba3c5c9f7d57f4fc63a80))
* base version for mapproxy customed ([c96149f](https://github.com/MapColonies/mc-mapproxy/commit/c96149f1f4ebef78cf96f098c94921e210087c7f))
* enhance S3 integration with urllib3 and add username support in configuration ([dcc26f1](https://github.com/MapColonies/mc-mapproxy/commit/dcc26f137e3425eac5600ca909a78b6eee8a88f4))
* helm chart added ([71390c0](https://github.com/MapColonies/mc-mapproxy/commit/71390c08e23a074da1aadebaa5fa44376262849b))
* **helm:** upgrade nginx chart to 2.2.1 ([eb3099b](https://github.com/MapColonies/mc-mapproxy/commit/eb3099bad1e30ef32c82dbc89eb88a6dffbcc71e))
* **helm:** upgrade nginx chart to 2.2.1 ([81355d0](https://github.com/MapColonies/mc-mapproxy/commit/81355d08978815e12da7ea8a3e38df9fdf125f11))
* silent fail on timeout from redis ([59b55ae](https://github.com/MapColonies/mc-mapproxy/commit/59b55aedaaff901c9aa85a7f7f8936298caf7177))
* update nginx configuration to enable extensions and adjust log format ([ffbb3e5](https://github.com/MapColonies/mc-mapproxy/commit/ffbb3e59e9d48a633058c6385bef94cd3bcb3e27))
* upgrade nginx to version 2.1.5 and refactor configuration files ([6e934d3](https://github.com/MapColonies/mc-mapproxy/commit/6e934d34b66f6ae82c67389a514262f6ba319516))


### Bug Fixes

* add REDIS_RETRY_ATTEMPTS environment variable to control retry behavior ([d74767d](https://github.com/MapColonies/mc-mapproxy/commit/d74767d5a9ed74b80ae4dc65b6d77713d572d668))
* correct comment formatting for sslCertReqs in values.yaml ([72ecc81](https://github.com/MapColonies/mc-mapproxy/commit/72ecc81dcd2ad09e62b30ac5595e62fc07e7f88d))
* disable OpenAPI lint check in pull request workflow ([c7a17cc](https://github.com/MapColonies/mc-mapproxy/commit/c7a17cc35df94dc4f159189bae8b72306522c1d4))
* enhance redis connection handling with conditional SSL parameters and import verification ([89d564b](https://github.com/MapColonies/mc-mapproxy/commit/89d564be93ebfe46a75997f4323e37fa249048b6))
* ensure sampling ratio denominator is at least 1 for telemetry tracing ([73b83bd](https://github.com/MapColonies/mc-mapproxy/commit/73b83bdd35e7ff25170b6b1cdd8b73c0f3a93e09))
* ensure socket timeouts are parsed as strings for Redis connection ([783a339](https://github.com/MapColonies/mc-mapproxy/commit/783a33942b7e96d09ed773832a0f4fea08438567))
* headers namings ([e261a4b](https://github.com/MapColonies/mc-mapproxy/commit/e261a4b62d792b88c56b53e86dfc5e4410bf0b3c))
* **helm:** align nginx config with common chart extension pattern ([cdeaefa](https://github.com/MapColonies/mc-mapproxy/commit/cdeaefabc015016f688e25b5c99230c3c298caec))
* **helm:** default nginx-config volume pointed at nonexistent configmap ([b06be3c](https://github.com/MapColonies/mc-mapproxy/commit/b06be3c443d47a939a38f767463938c002af22c6))
* **helm:** suppress chart-level CORS headers duplicated with MapProxy's ([b97cd10](https://github.com/MapColonies/mc-mapproxy/commit/b97cd10911c11f440f79a46ef2c23afd162215ff))
* **helm:** update nginx nameOverride to mapproxy-nginx ([8a3b3be](https://github.com/MapColonies/mc-mapproxy/commit/8a3b3beb1c589e865fe4c92dcfb90b45199e0df8))
* indentaion ([1fe72c0](https://github.com/MapColonies/mc-mapproxy/commit/1fe72c00bc50bbaaf5d16c229d45e0085caee73d))
* make patch guard enforced under -O (use sys.exit, not assert) ([4f82411](https://github.com/MapColonies/mc-mapproxy/commit/4f82411a7cec060abaf8b482e1dba3a85fa22e85))
* readme ([cc16443](https://github.com/MapColonies/mc-mapproxy/commit/cc16443e4a8fbcdc537623f69ec2f702df35241a))
* redis error causes timeout instead of s fallback ([6ae5e40](https://github.com/MapColonies/mc-mapproxy/commit/6ae5e40cb9871ec1dc31bcd8e97f4f0004ea0d66))
* redis timeout bug was waiting for too long ([ebb1097](https://github.com/MapColonies/mc-mapproxy/commit/ebb10976f7c98b0c4af973ca8d009cc3e294f310))
* remove not needed github actions ([f1aa4c0](https://github.com/MapColonies/mc-mapproxy/commit/f1aa4c0fc31f9f6c44fa1d8d998daf7d3a00d6e0))
* remove unnecessary attributes from Redis and Boto request hooks ([864a000](https://github.com/MapColonies/mc-mapproxy/commit/864a00058c148687fb0d7da479504b169942e381))
* rename ([d4b1438](https://github.com/MapColonies/mc-mapproxy/commit/d4b1438963db8a011a075d6ae31c2b6e3f31f29e))
* rename storage references from 'sources-storage' to 'internal-storage' in Helm templates ([a04ed09](https://github.com/MapColonies/mc-mapproxy/commit/a04ed094fd3af7d17852a40a2c9a8b639780458c))
* restore S3Cache method indentation and harden patch guard ([d8ab355](https://github.com/MapColonies/mc-mapproxy/commit/d8ab355c6e8001872c3b9970aff69952666d657a))
* restore S3Cache method indentation and harden patch guard ([081e7d0](https://github.com/MapColonies/mc-mapproxy/commit/081e7d09e63465aa06e75ef49465f605e87a3ad4))
* size s3 http pool to batch concurrency ([fa1bf2e](https://github.com/MapColonies/mc-mapproxy/commit/fa1bf2e64adf6ffdfdcf7861e2bceab888194b4d))
* update Redis configuration for optional SSL certificate requirements and remove pool timeout ([84ff979](https://github.com/MapColonies/mc-mapproxy/commit/84ff979fcb7c682df55718c75e8d539dc10813b1))
* update Redis dependency to use hiredis and add S3 patch support ([75ebaeb](https://github.com/MapColonies/mc-mapproxy/commit/75ebaebc7092233b43faa2f50f97174315120b5c))
* update version in Chart.yaml and remove uid/gid from mapProxyUwsgi.ini ([dfd1c42](https://github.com/MapColonies/mc-mapproxy/commit/dfd1c425a45635e08b20aeb4994f38d5bd6ee6c8))
* wrap redis pexpire in store_tile's try/except ([62c849e](https://github.com/MapColonies/mc-mapproxy/commit/62c849ed121c55fb2f44cdcf5163ffb0026d309f))
