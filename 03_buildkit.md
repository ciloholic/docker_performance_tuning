# Buildkitによるイメージ構築

Buildkitは、新たな`docker build`として開発されたビルドツールキットです。`DOCKER_BUILDKIT=1`を設定することで利用できます。

Buildkitを利用することでビルドの高速化が行えます。

- ステージ間の依存関係を解析し、ビルドを並列化する
- cacheやsecret用のmount機能が提供されており、各種パッケージマネージャーのキャッシュや秘密鍵等をレイヤーに含めることなく利用できる
- build contextが差分転送になる

```
$ DOCKER_BUILDKIT=1 docker build .
```
