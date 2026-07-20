# Release checklist

Attach an owner and evidence link to every applicable item. `N/A` requires a
reason and approver. This checklist does not establish legal compliance.

## Scope and change control

- [ ] Version/build number, commit, image digest, migration head, release notes,
      supported OS/API protocol, and rollback owner are recorded.
- [ ] Product owner confirms shipped/deferred features; unfinished controls do
      not display fabricated success.
- [ ] Breaking API/sync/data changes have a compatible migration window.
- [ ] Known risks/debt have owner, severity, mitigation, and expiry.

## Quality

- [ ] Python format/lint/tests and Flutter format/analyze/tests pass.
- [ ] Financial contract vectors and edge cases pass in every implementing runtime.
- [ ] PostgreSQL migration empty-to-head and supported upgrade rehearsal pass.
- [ ] Critical end-to-end journeys pass on supported mobile and desktop targets.
- [ ] Packaged artifact launch/restart/offline/sync/clean-exit smoke is recorded.
- [ ] Performance/load targets pass with production-like data volumes.
- [ ] No critical/high flaky test is waived without explicit risk acceptance.

## Security and privacy

- [ ] Secret, dependency, SAST, container, SBOM, and license scans reviewed.
- [ ] Two-user authorization/IDOR, token replay/rotation, rate-limit, upload,
      export, deletion, and AI adversarial suites pass.
- [ ] No development credentials, debug mode, wildcard CORS, or provider secrets
      exist in production configuration/client artifacts.
- [ ] Logs, crashes, metrics, notifications, app switcher, clipboard, and exports
      are checked for sensitive leakage.
- [ ] Penetration/threat-model findings are remediated or formally accepted.
- [ ] Privacy data inventory, retention/deletion, processors, AI consent, privacy
      policy, terms, and permission copy received appropriate review.
- [ ] Signing keys and privileged production access use audited least privilege.

## Data integrity and operations

- [ ] Transfer atomicity, balance reconciliation, rounding, time zone, idempotency,
      tombstone, and critical conflict behavior pass.
- [ ] Pre-release backup completed and a recent isolated restore was verified.
- [ ] Database/object lifecycle capacity, connection pools, quotas, and alerts are
      reviewed.
- [ ] Health/readiness/liveness, dashboards, alerts, on-call, incident contacts,
      status/support paths, and provider limits are ready.
- [ ] Migration, deploy, canary, rollback/read-only recovery, and key rotation
      procedures have been rehearsed.

## AI

- [ ] Application starts and core features work with AI disabled.
- [ ] Configured adapters pass provider contract and regional/retention review.
- [ ] Tool schemas/scopes/rate limits/result bounds and server reauthorization
      are verified.
- [ ] Recommendations show evidence, assumptions, uncertainty, alternatives, and
      appropriate educational disclaimer.
- [ ] Exact-diff approval rejects payload swap, stale version, expiry, replay, and
      concurrent reuse; the model cannot approve its own action.
- [ ] Token/cost/safety telemetry is useful and contains no sensitive content.

## Accessibility and localization

- [ ] Keyboard, focus, screen reader, scalable text, contrast, reduced motion,
      non-color status, target size, error announcements, and chart summaries pass.
- [ ] Compact/medium/expanded layouts and supported desktop resizing pass.
- [ ] English copy is reviewed; no hard-coded strings; currency/date/number,
      pluralization, week-start, and RTL readiness are tested.

## Store and artifact readiness

- [ ] Icons, splash, descriptions, screenshots, support/privacy URLs, permissions,
      data-safety/privacy manifests, age/content ratings, and legal attribution are complete.
- [ ] Android/iOS/macOS/Windows artifacts are signed/notarized as required; Linux
      package checksums/signatures and direct-download verification are prepared.
- [ ] Crash symbols, update strategy, minimum versions, release channel, and staged
      rollout/stop criteria are recorded.
- [ ] Final install and upgrade from the oldest supported version pass on clean
      and existing-data devices.

## Approval and post-release

- [ ] Engineering, product, security/privacy, operations/support, and release owner approve.
- [ ] Staged rollout started with named monitor and rollback window.
- [ ] Post-release smokes pass; telemetry and support queues are monitored.
- [ ] Release evidence is archived and follow-up debt is filed.
