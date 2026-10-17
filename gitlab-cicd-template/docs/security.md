# Security and Quality Notes

- Keep secrets in masked/protected CI variables; do not put deployment credentials in YAML.
- `SECURITY_TOOLS` supports comma-separated `trivy`, `dependency-check`, and `container-scan`. Runner images must contain the selected tools.
- Pre secret scanning uses Trivy when installed and a portable grep fallback otherwise.
- Dependency audit currently detects npm lockfiles and Python requirements when `pip-audit` exists. Missing scanner tools are reported instead of silently treated as a clean scan.
- The Java sample emits JaCoCo XML. `TEST_COVERAGE_MIN` fails when a supported report is missing or below threshold.
- A default deploy only stages `build-output/`; actual environment changes require an application-owned `DEPLOY_COMMAND`.
