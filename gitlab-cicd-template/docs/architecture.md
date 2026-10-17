# Template Architecture

`10_pipeline_standard.yml` owns shared defaults. Applications directly include `includes/all_stages.yml` for hidden stage templates and `includes/app_pipeline.yml` for executable APP_TYPE-specific jobs. The application declares its `stages` list, `workflow` rules, and application-specific variables. It selects an `APP_TYPE`; the shared pipeline creates matching jobs with their stage placement and dependencies. Application repositories do not declare execution jobs.

The included YAML lives in the application pipeline context, while scripts live in this repository. Each job therefore checks out `TEMPLATE_PROJECT_PATH` at `TEMPLATE_REF` using `CI_JOB_TOKEN` before invoking a script. Configure the template project's Job Token allowlist for each consuming application.

Pre checks share one stage/job. E2E owns app startup, readiness polling, Playwright execution, process termination, and cleanup. No startup stage is exposed.
