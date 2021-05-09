# Docker for Macが遅い

Docker for Macが遅いと言われる理由の1つが、マウントしているボリュームの同期です。

## ボリュームの同期が遅い原因

Docker for Macがファイルシステム共有に`osxfs`を採用しており、ホストとコンテナが異なるファイルシステムを利用していても共有できるようにしています。例えば、コンテナで`Ubuntu`を利用する場合は、`VFS(Virtual File System)`と`APFS(Apple File System)`の異なるファイルシステムを共有することになります。

ホストとコンテナ間で`VFS`を基盤にしていた場合、共有するためのオーバーヘッドは発生しません。しかし、macOS、またはLinux以外のプラットフォームでは、完全な一貫性を保つために著しいオーバーヘッドが発生します。

このパフォーマンス劣化は、`osxfs`を採用しているDocker for Mac固有のもので、WindowsやLinuxでは発生しません。

## 回避策

- Macを使わずに、Ubuntu Desktopなどを使う
- VM上のLinuxでDockerを使う
- volumesオプションの`cached`、`delegated`を使う
- `docker-sync`などでファイル同期させる
