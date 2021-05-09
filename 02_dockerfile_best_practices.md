# Dockerfileのベストプラクティス

## .dockerignoreを使ったファイル除外の指定

ビルドに関係の無いファイルを除外するには`.dockerignore`ファイルを利用します。必要も無いのに巨大なファイルや取り扱い注意のファイルを不用意に送信してしまうことが避けられ、`ADD`や`COPY`を使ってイメージに間違って送信してしまうことを防ぐことができます。

```
# comment
*/temp*
*/*/temp*
temp?
```

## マルチステージビルドの利用

本来、アプリケーションのビルドに必要なツール・依存するライブラリはDockerイメージには不要です。マルチステージビルドを利用すると、不要なファイルを含めずに最終的なイメージサイズを激減させることができます。

```
##############################
# ビルド用イメージ
##############################
# 最終イメージで参照するため、buildという別名を付ける
FROM golang:1.16-alpine AS build

# 本プロジェクトに必要なツールをインストール
RUN apk add --no-cache git
RUN go get github.com/golang/dep/cmd/dep

COPY Gopkg.lock Gopkg.toml /go/src/project/
WORKDIR /go/src/project/

# 依存ライブラリをインストール
RUN dep ensure -vendor-only

# プロジェクト全体をコピーしてビルド
COPY . /go/src/project/
RUN go build -o /bin/project

##############################
# 最終イメージ
##############################
FROM scratch

# ビルド用イメージからコピーする
COPY --from=build /bin/project /bin/project
ENTRYPOINT ["/bin/project"]
CMD ["--help"]
```

## ビルドキャッシュの利用

Dockerイメージの構築時にDockerfile内に示されている命令を記述順に実行していきます。個々の命令が処理される際にDockerは、既存イメージのキャッシュが再利用できるかどうかを調べます。

### ADDとCOPYの場合

Dockerイメージに含まれるファイルの内容が検査され、個々のファイルについてチェックサムが計算されます。 この計算において、ファイルの最終更新時刻、最終アクセス時刻は考慮されません。キャッシュを探す際に、このチェックサムと既存イメージのチェックサムが比較されます。

### ADDとCOPY以外の場合

キャッシュのチェックは、コンテナ内のファイル内容を見ることはなく、それによってキャッシュと合致しているかどうかが決定されるわけでありません。コマンド文字列そのものがキャッシュの合致判断に用いられます。

## RUNコマンド

### パッケージインストール

`RUN apt-get update`と`apt-get install`は、同一の`RUN`コマンド内にて実行する。

1つの`RUN`コマンド内で`apt-get update`だけを使うとキャッシュされてしまい、追加で`nginx`をインストールしようとした場合、`apt-get update`が実行されずに古いバージョンがインストールされる可能性があります。

```
FROM ubuntu:latest
RUN apt-get update
- RUN apt-get install -y curl
+ RUN apt-get install -y curl nginx
```

### Dockerイメージサイズの削減

ファイルを削除する際は、同一の`RUN`コマンド内で実行する。

レイヤーは読み込み専用のため、下記のように`RUN`コマンドを分割すると別レイヤーになり、`/var/lib/apt/lists/*`が削除されない。

```
FROM ubuntu:latest
RUN apt-get update && \
    apt-get install -y curl
RUN rm -rf /var/lib/apt/lists/*
```

```
# Dockerイメージの履歴
$ docker history docker_performance_tuning_ubuntu:latest
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
202f582f2c03   12 seconds ago   RUN /bin/sh -c rm -rf /var/lib/apt/lists/* #…  0B        buildkit.dockerfile.v0
<missing>      13 seconds ago   RUN /bin/sh -c apt-get update &&     apt-get…  44.2MB    buildkit.dockerfile.v0
=== 省略 ===
```

```
# Dockerイメージのサイズ
$ docker images | grep ubuntu
docker_performance_tuning_ubuntu   latest          202f582f2c03   About a minute ago   117MB
```

レイヤーにファイルを含めたくない場合は、同一の`RUN`コマンド内で`/var/lib/apt/lists/*`を削除する。

```
FROM ubuntu:latest
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*
```

```
# Dockerイメージの履歴
$ docker history docker_performance_tuning_ubuntu:latest
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
774c079e5f64   38 seconds ago   RUN /bin/sh -c apt-get update &&     apt-get…  16.2MB    buildkit.dockerfile.v0
=== 省略 ===
```

```
# Dockerイメージのサイズ
$ docker images | grep ubuntu
docker_performance_tuning_ubuntu   latest          265129d6fc5e   11 seconds ago   88.9MB
```

## ADDとCOPY

`ADD`と`COPY`の機能は似ていますが、`COPY`は単にローカルファイルをコンテナにコピーするだけなのに対し、`ADD`はtar展開やリモートURL先ファイルをコピーします。

`ADD`でリモートURL先ファイルを取得するとDockerイメージからファイルを削除できなくなるので、代わりに`curl`か`wget`を利用してください。

`ADD`の自動展開機能を必要としないものに対しては、常に`COPY`を使うようにしてください。
