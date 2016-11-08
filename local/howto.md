# ちょっと改造して動かす手順

このブランチはちょっとした都合により某環境で動かすための変更を入れています。  
任意のDocker環境で動かすには次のようにしましょう。

- ソースを変更する(任意)
    - 認証スキップなど
- 設定ファイルをコピー、元ネタに更新があったら差分を確認しよう。
    - test/config to local/config
    - test/config-next to local/config-next
    - test/rate-limit-policies.yml to local/rate-limit-policies.yml

これらをローカル向けの値などに変更します。

## compose up

```
docker-compose build
docker-compose up
```
