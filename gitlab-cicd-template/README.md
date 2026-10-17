# GitLab Common CI/CD Templates v1.0.0

GitLab標準の`include` / `extends`で再利用するJob Template集です。共通側は処理と既定値を提供し、アプリ側がPipeline構造・Job選択・実行条件・デプロイ戦略を所有します。

## 目次

- [GitLab Common CI/CD Templates v1.0.0](#gitlab-common-cicd-templates-v100)
  - [目次](#目次)
  - [使い方](#使い方)
  - [アプリ側の設定](#アプリ側の設定)
  - [APP_TYPE](#app_type)
  - [Stage](#stage)
  - [Job Template](#job-template)
  - [Quality Policy](#quality-policy)
  - [Quality Rule](#quality-rule)
  - [変数](#変数)
    - [GitLab CI/CD設定で管理する変数](#gitlab-cicd設定で管理する変数)
    - [セキュリティ管理する変数](#セキュリティ管理する変数)
  - [Examples](#examples)
  - [GitFlow](#gitflow)
  - [Trunk Based](#trunk-based)
  - [Vue + Spring Boot](#vue--spring-boot)
  - [Python](#python)
  - [Batch](#batch)
  - [Manual Deploy](#manual-deploy)
  - [実行と権限](#実行と権限)

## 使い方

1. `gitlab-cicd-template`をGitLabプロジェクトとして公開し、`v1.0.0`タグを作成します。
2. アプリの`.gitlab-ci.yml`から`includes/all_stages.yml`と`includes/app_pipeline.yml`を直接includeし、同じ`ref: v1.0.0`を指定します。
3. `YOUR_GROUP`をテンプレートプロジェクトのnamespaceに置き換えます。
4. アプリ側で`APP_TYPE`、アプリ固有変数、`stages`、Pipeline起動条件の`workflow`を定義します。共通側がJob、stageへの配置、依存関係、Deployの手動条件を設定します。

テンプレートJobは`CI_JOB_TOKEN`を使い、実行時にテンプレートリポジトリの同じタグを`.gitlab-cicd-template/`へチェックアウトします。GitLabのJob Token allowlistでアプリプロジェクトを許可してください。

## アプリ側の設定

```yaml
include:
  - project: &template_project YOUR_GROUP/gitlab-cicd-template
    ref: &template_ref v1.0.0
    file: /gitlab_cicd_templates/includes/all_stages.yml
  - project: *template_project
    ref: *template_ref
    file: /gitlab_cicd_templates/includes/app_pipeline.yml

workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: "$CI_COMMIT_BRANCH"
    - if: "$CI_COMMIT_TAG"

  stages: [40_pre, 51_build, 52_test, 53_e2e, 54_security, 55_performance, 56_deploy, 57_release, 58_cleanup, 59_notify]

variables:
  TEMPLATE_PROJECT_PATH: *template_project
  TEMPLATE_REF: *template_ref
  APP_NAME: example-service
  APP_TYPE: springboot
```

`all_stages.yml`は各stageの隠しJob Templateを読み込み、`app_pipeline.yml`は`APP_TYPE`別の実行Jobを定義します。どちらもアプリの`.gitlab-ci.yml`から直接includeします。アプリ側では`stages`の一覧と`workflow`を定義し、Jobそのものは定義しません。Jobのstage配置と依存関係は共通側が制御します。

## APP_TYPE

Preで検証する値は`tomcat`、`springboot`、`vue-springboot`、`react-springboot`、`python`、`was`、`liberty`です。アプリが`APP_TYPE`を1つ指定すると、共通側が対応するBuild/Test/Deploy Jobと依存関係を選びます。E2E対応タイプでは`STARTUP_URL`と`PLAYWRIGHT_DIR`の両方が設定されている場合に限り、E2E Jobを追加します。すべてのタイプでPreとSecurityを実行し、`PERFORMANCE_URL`が設定されている場合はPerformance Jobも追加します。Release Jobはバージョンタグで実行します。

| APP_TYPE           | 共通側が選択する主なJob                                      |
| ------------------ | ------------------------------------------------------------ |
| `springboot`       | Spring Boot Build/Test/E2E/Deploy                            |
| `vue-springboot`   | Vue frontendとSpring Boot backendのBuild/Test、E2E、Deploy   |
| `react-springboot` | React frontendとSpring Boot backendのBuild/Test、E2E、Deploy |
| `tomcat`           | Tomcat Build/Test/E2E/Deploy                                 |
| `python`           | Python Build/Test/E2E/Deploy                                 |
| `was`              | WAS Build/Test/Deploy                                        |
| `liberty`          | Liberty Build/Test/E2E/Deploy                                |

## Stage

| 番号 | 推奨stage名      | 用途                                                                              |
| ---- | ---------------- | --------------------------------------------------------------------------------- |
| 10   | Pipeline         | Pipeline全体の分類番号。stageではありません                                       |
| 40   | `40_pre`         | Validate、Secret/Dependency scan、SBOM、License、SAST、Policy Gateを単一Jobで実行 |
| 51   | `51_build`       | ビルド                                                                            |
| 52   | `52_test`        | 単体・結合テスト                                                                  |
| 53   | `53_e2e`         | 内部で起動、Playwright、停止、cleanup                                             |
| 54   | `54_security`    | 選択したセキュリティスキャナー                                                    |
| 55   | `55_performance` | 負荷・性能確認                                                                    |
| 56   | `56_deploy`      | 共通側が選択するDeploy Job。対象ブランチではmanual                                |
| 57   | `57_release`     | GitLab Releaseとリリース情報                                                      |
| 58   | `58_cleanup`     | 一時テンプレートcheckoutの削除                                                    |
| 59   | `59_notify`      | Webhook通知またはログ出力                                                         |

`stages`の一覧はアプリ側で宣言します。共通側のJob Templateが各Jobのstage配置を行います。Startup stage/jobは公開していません。

## Job Template

| Stage                      | Template                                                                                                                              |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| Pre                        | `.common_pre`                                                                                                                         |
| Build                      | `.vue_frontend_build`, `.react_frontend_build`, `.springboot_build`, `.tomcat_build`, `.python_build`, `.was_build`, `.liberty_build` |
| Test                       | `.vue_frontend_test`, `.react_frontend_test`, `.springboot_test`, `.tomcat_test`, `.python_test`, `.was_test`, `.liberty_test`        |
| E2E                        | `.springboot_e2e`, `.tomcat_e2e`, `.python_e2e`, `.liberty_e2e`                                                                       |
| Security / Performance     | `.security_scan`, `.performance_test`                                                                                                 |
| Deploy                     | `.springboot_deploy`, `.tomcat_deploy`, `.python_deploy`, `.was_deploy`, `.liberty_deploy`                                            |
| Release / Cleanup / Notify | `.application_release`, `.template_cleanup`, `.pipeline_notify`                                                                       |

## Quality Policy

`PRE_VALIDATE_ENABLED`、`PRE_SECRET_SCAN_ENABLED`、`PRE_DEPENDENCY_SCAN_ENABLED`、`PRE_SBOM_ENABLED`、`PRE_LICENSE_ENABLED`、`PRE_SAST_ENABLED`、`PRE_POLICY_GATE_ENABLED`は文字列`"true"`/`"false"`で切り替えます。Preは常に`40_pre`の1 Jobです。任意ツールがrunnerにない場合、SBOM/License/SASTは警告付きでskipします。Secret scanはTrivyがなければgrepベースの検査にfallbackします。

## Quality Rule

`SECRET_SCAN_FAIL_ON_FOUND`は秘密情報検出時の失敗、`CVE_FAIL_SEVERITY`はDependency/Securityのseverity、`LICENSE_DENY_LIST`は拒否ライセンスのカンマ区切り、`SAST_FAIL_SEVERITY`はSASTしきい値、`POLICY_GATE_FAIL_FAST`はPreチェックの即時失敗、`TEST_COVERAGE_MIN`は0-100の最低line coverageです。カバレッジしきい値を0より大きくする場合、Pythonはcoverage report、JVMはJaCoCo XMLを生成してください。

## 変数

| Variable                                      | Default                           | 説明                                                            |
| --------------------------------------------- | --------------------------------- | --------------------------------------------------------------- |
| `TEMPLATE_PROJECT_PATH`                       | `YOUR_GROUP/gitlab-cicd-template` | テンプレートのGitLab namespace/project                          |
| `TEMPLATE_REF`                                | `v1.0.0`                          | Job script checkout ref                                         |
| `NODE_VERSION` / `PYTHON_VERSION`             | `22` / `3.12`                     | Runtime image                                                   |
| `SECURITY_TOOLS`                              | `trivy`                           | `trivy`, `dependency-check`, `container-scan`のカンマ区切り     |
| `FRONTEND_DIR` / `BACKEND_DIR` / `PYTHON_DIR` | `frontend` / `backend` / `.`      | ソース配置                                                      |
| `STARTUP_COMMAND` / `BACKEND_STARTUP_COMMAND` | 空                                | E2E内部起動コマンド                                             |
| `STARTUP_URL`                                 | 空                                | E2E開始前のreadiness URL                                        |
| `DEPLOY_COMMAND`                              | 空                                | アプリ側のデプロイコマンド。未指定時はbuild-outputへstagingのみ |
| `NOTIFY_WEBHOOK_URL`                          | 空                                | 通知先Webhook                                                   |
| `GITLAB_RELEASE_TOKEN`                        | 空                                | GitLab Release作成用のmasked token                              |
| `PERFORMANCE_URL`                             | 必須                              | 性能テスト対象URL                                               |

加えて`APP_NAME`、`APP_TYPE`、`DEPLOY_ENV`などアプリ固有変数は利用側が定義します。

### GitLab CI/CD設定で管理する変数

リポジトリに値を置きたくないcredentialや環境ごとに異なる値は、GitLabの`Settings > CI/CD > Variables`で設定します。複数プロジェクトで共有する場合はGroup CI/CD Variablesを利用できます。以下は共通テンプレートが参照する外部設定値です。

| Variable                  | 必須条件・既定値                    | 用途                                                                                  |
| ------------------------- | ----------------------------------- | ------------------------------------------------------------------------------------- |
| `PERFORMANCE_URL`         | Performance Jobを実行する場合は必須 | 負荷・性能テストの対象URL。環境別のURLはenvironment scopeで分けます。                 |
| `PERFORMANCE_COMMAND`     | 任意                                | `hey`の代わりに実行する性能テストコマンド。未設定時は`hey`を使います。                |
| `PERFORMANCE_REQUESTS`    | 任意、既定値`100`                   | `hey`で送るリクエスト数。                                                             |
| `PERFORMANCE_CONCURRENCY` | 任意、既定値`5`                     | `hey`の同時実行数。                                                                   |
| `DEPLOY_COMMAND`          | 実際にDeployする場合に設定          | アプリ側のDeployコマンド。未設定時は成果物を`build-output/deploy`へ配置するだけです。 |
| `DEPLOY_OUTPUT_DIR`       | 任意、既定値`build-output/deploy`   | Deploy成果物の配置先。                                                                |
| `NOTIFY_WEBHOOK_URL`      | Webhook通知を使う場合に設定         | 通知先URL。認証情報を含むURLは機密値として扱います。                                  |
| `GITLAB_RELEASE_TOKEN`    | GitLab Releaseを作成する場合に設定  | Release API用token。未設定時はローカルにRelease metadataを作成します。                |
| `RELEASE_VERSION`         | 任意                                | Releaseに使うバージョン。未設定時はtag名を使います。                                  |
| `NOTIFY_STATUS`           | 任意、既定値`success`               | 通知メッセージに表示する状態。                                                        |

`PRE_*`、`*_FAIL_*`、`CVE_FAIL_SEVERITY`など前述のQuality Policy/Ruleおよび共通変数も、GitLab CI/CD Variablesから上書きできます。GitLabの変数優先順位により、Settings側の値がYAMLの既定値より優先されるため、同じ変数を複数の場所で設定しないようにしてください。現在のサンプルでは`TEMPLATE_PROJECT_PATH`と`TEMPLATE_REF`をアプリの`.gitlab-ci.yml`でincludeとcloneの共通値として定義しています。これらをSettings側で上書きすると参照先がずれるため、外部設定には登録しないでください。

### セキュリティ管理する変数

credentialや秘密情報はYAMLやリポジトリに記載せず、GitLab CI/CD Variablesに登録します。利用可能な場合は`Masked`と`Protected`を有効にし、対象環境をenvironment scopeで制限してください。`Protected`変数はprotected branch/tagのPipelineでのみ利用できます。

| Variable               | 機密性と用途                                                                                      | 管理方法                                                                                                                            |
| ---------------------- | ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| `GITLAB_RELEASE_TOKEN` | Release API認証token                                                                              | `Masked`、`Protected`を有効化し、必要最小限のAPI権限を付与します。                                                                  |
| `NOTIFY_WEBHOOK_URL`   | 通知URLに認証tokenが含まれる場合はsecret                                                          | `Masked`、`Protected`を有効化します。マスク要件を満たさない値はログに出さず、利用可能なsecret管理方法を使います。                   |
| Deploy先のcredential   | `DEPLOY_COMMAND`が利用するクラウド/API/デプロイ先の認証情報。名前は利用サービスにより異なります。 | credentialを`DEPLOY_COMMAND`へ埋め込まず、個別の`Masked`/`Protected`変数として登録します。最小権限とenvironment scopeを適用します。 |
| `CI_JOB_TOKEN`         | テンプレートリポジトリのcloneに使うGitLab事前定義token                                            | 利用者が作成・登録する変数ではありません。テンプレートプロジェクトのJob Token allowlistでアプリプロジェクトを許可します。           |

`DEPLOY_COMMAND`自体はcredentialではありません。コマンド文字列をYAMLに置く場合も、秘密値は別のCI/CD変数から参照してください。`TEMPLATE_PROJECT_PATH`、`TEMPLATE_REF`、`APP_NAME`、`APP_TYPE`などはサンプルではアプリ側YAMLで管理する非secret設定です。

## Examples

- `examples/vue-springboot/`: Vue + Spring Boot向けのBuild/Test/E2E/Security/Manual Deploy。
- `examples/react-springboot/`: React + Spring Boot向けBuild/Test/Security。
- `examples/python/`: 実行可能なPython関数・pytestとPipeline。
- `examples/liberty/`: Servlet WAR、JUnit、Open Liberty設定とPipeline。
- ワークスペースの`project-app/`: Vue + Spring Boot + H2の動作サンプル。

各exampleの`.gitlab-ci.yml`はAPP_TYPE、アプリ固有変数、`stages`、`workflow`のみを宣言します。実行Jobは共通側の`app_pipeline.yml`がAPP_TYPEに応じて選択するため、example側にJob定義を重複記載しません。

## GitFlow

Pipelineを作成するブランチ戦略はアプリ側の`workflow`に置きます。Deploy Job自体は共通側が`main`、`master`、`release/*`でmanualとして作成し、バージョンtagではRelease Jobを作成します。release branchとtagだけを許可する例:

```yaml
workflow:
  rules:
    - if: '$CI_COMMIT_BRANCH =~ /^release\//'
    - if: '$CI_COMMIT_TAG =~ /^v[0-9]+\.[0-9]+.*$/'
```

## Trunk Based

短命branch/MRで検証し、Pipelineを作成するbranchをアプリ側で選択します。共通側のDeploy Jobは`main`、`master`、`release/*`でmanualです。

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH"
```

## Vue + Spring Boot

`APP_TYPE: vue-springboot`を指定すると、共通側がVue frontendとSpring Boot backendのBuild/Test、E2E、Deployを選び、stageと`needs`を設定します。アプリ側で個別Jobを宣言する必要はありません。

## Python

`APP_TYPE: python`と必要に応じて`PYTHON_DIR`を設定すると、Python Build/Test/E2E/Deployを共通側が選びます。Buildはcompileallとtar artifactを作り、Testはpytestを実行します。

## Batch

Batchでも`APP_TYPE: python`により標準Jobを共通側が選びます。Scheduled Pipelineを使う場合は、アプリ側の`workflow`でscheduleを許可します:

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
    - if: "$CI_COMMIT_BRANCH"
```

## Manual Deploy

共通側が`APP_TYPE`に応じたDeploy Jobを選び、`main`、`master`、`release/*`ではmanualにします。アプリ側は必要な`DEPLOY_COMMAND`とcredentialを設定します。`DEPLOY_COMMAND`未指定の場合、共通deploy scriptは`build-output/`にartifactを配置するだけです。

## 実行と権限

- `gitlab_cicd_templates/scripts/tests/smoke_test.sh`でPre scriptの簡易テストを実行できます。
- `SECURITY_TOOLS`で複数指定できます（例: `trivy,dependency-check`）。対象ツールはrunner imageにインストールしてください。
- `include:project`のファイル読み込みとCI_JOB_TOKENによるscript checkoutの両方で、アプリからテンプレートプロジェクトへのアクセスが必要です。
- デプロイ・通知・ReleaseのcredentialはGitLab CI/CDのmasked/protected variablesに登録してください。
- 定義は`include`、`extends`、`workflow`、`rules`、`stages`、`variables`、`needs`、`artifacts`、`when`など標準機能のみを利用し、特定GitLabバージョン固有機能には依存しません。
