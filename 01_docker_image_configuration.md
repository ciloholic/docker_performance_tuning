# Dockerイメージの構成

Dockerイメージは、読み取り専用のレイヤーにより構成されます。個々のレイヤーは、Dockerfileの各命令を表現しています。レイヤーは、順に積み上げられ、それぞれは直前のレイヤーからの差分を表わします。

下記のDockerfileのレイヤーを見てみます。

```
FROM ubuntu:latest
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*
RUN dd if=/dev/zero of=1M.dummy bs=1M count=1
```

`FROM`をベースイメージとして、各コマンドから1つずつレイヤーが生成されます。

下記はベースイメージとなった`ubuntu:latest`のレイヤーの履歴です。

```
$ docker history ubuntu:latest
IMAGE          CREATED       CREATED BY                                      SIZE      COMMENT
7e0aa2d69a15   2 weeks ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B        
<missing>      2 weeks ago   /bin/sh -c mkdir -p /run/systemd && echo 'do…  7B        
<missing>      2 weeks ago   /bin/sh -c [ -z "$(apt-get indextargets)" ]     0B        
<missing>      2 weeks ago   /bin/sh -c set -xe   && echo '#!/bin/sh' > /…  811B      
<missing>      2 weeks ago   /bin/sh -c #(nop) ADD file:5c44a80f547b7d68b…  72.7MB    
```

下記はDockerfileからビルドされたDockerイメージのレイヤーの履歴です。

2コマンド分のレイヤーが生成されていることが確認できます。また、`dd`コマンドでダミーファイルを1MB作成したため、レイヤーの`SIZE`が約1MBになっているのが確認できます。

```
$ docker history docker_performance_tuning_ubuntu:latest
IMAGE          CREATED          CREATED BY                                      SIZE      COMMENT
97de2a05dad4   3 minutes ago    RUN /bin/sh -c dd if=/dev/zero of=1M.dummy b…   1.05MB    buildkit.dockerfile.v0
<missing>      49 minutes ago   RUN /bin/sh -c apt-get update &&     apt-get…   16.2MB    buildkit.dockerfile.v0
<missing>      2 weeks ago      /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B
<missing>      2 weeks ago      /bin/sh -c mkdir -p /run/systemd && echo 'do…   7B
<missing>      2 weeks ago      /bin/sh -c [ -z "$(apt-get indextargets)" ]     0B
<missing>      2 weeks ago      /bin/sh -c set -xe   && echo '#!/bin/sh' > /…   811B
<missing>      2 weeks ago      /bin/sh -c #(nop) ADD file:5c44a80f547b7d68b…   72.7MB
```

Dockerが軽量だと言われる理由の1つが、このレイヤーによるものです。

例えば、ダミーファイルを`10MB`作成するようにDockerfileを変更した場合、変更があったコマンド以降のレイヤーを再ビルドし直すだけで済みます。また、Dockerfileの末尾にコマンドを追加した場合は、追加したコマンド分のレイヤーを付け加えるだけで済みます。
