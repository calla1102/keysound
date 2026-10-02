앱 버전과 빌드 번호를 올린다. 사용자 입력: $ARGUMENTS (`major` | `minor` | `patch` | `x.y.z`, 비면 `patch`)

버전은 `project.yml` 의 `settings.base` 에만 있다. 두 타깃 Info.plist 는 `$(MARKETING_VERSION)`·`$(CURRENT_PROJECT_VERSION)` 을 참조하므로 따로 고치지 않는다(앱과 익스텐션 버전이 다르면 App Store 업로드가 거부된다).

## 절차

1. 현재 값 확인: `grep -nE 'MARKETING_VERSION|CURRENT_PROJECT_VERSION' project.yml`
2. 새 값 계산
   - `MARKETING_VERSION`: 인자대로 올린다(`patch` 0.1.0 → 0.1.1).
   - `CURRENT_PROJECT_VERSION`: **항상 +1**. 같은 버전으로 다시 올릴 때도 빌드 번호는 올라가야 한다.
3. 변경 전후를 보여주고 확인받은 뒤 project.yml 두 줄만 수정한다.
4. `xcodegen generate` 후 확인:
   ```bash
   xcodebuild -project Keysound.xcodeproj -scheme Keysound -showBuildSettings 2>/dev/null | grep -E 'MARKETING_VERSION|CURRENT_PROJECT_VERSION' | sort -u
   ```
5. 커밋은 작업 브랜치에서 `chore: 버전 <x.y.z> (<빌드>)`. main 직접 커밋은 전역 훅이 막는다.
