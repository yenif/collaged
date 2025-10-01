
# Implementation Plan: Collage Editing Functionality Recovery

**Branch**: `001-awesome-use-the` | **Date**: 2025-09-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/spec.md`
**User Context**: get frontend collage editing functionality working again

## Execution Flow (/plan command scope)
```
1. Load feature spec from Input path
   → If not found: ERROR "No feature spec at {path}"
2. Fill Technical Context (scan for NEEDS CLARIFICATION)
   → Detect Project Type from file system structure or context (web=frontend+backend, mobile=app+api)
   → Set Structure Decision based on project type
3. Fill the Constitution Check section based on the content of the constitution document.
4. Evaluate Constitution Check section below
   → If violations exist: Document in Complexity Tracking
   → If no justification possible: ERROR "Simplify approach first"
   → Update Progress Tracking: Initial Constitution Check
5. Execute Phase 0 → research.md
   → If NEEDS CLARIFICATION remain: ERROR "Resolve unknowns"
6. Execute Phase 1 → contracts, data-model.md, quickstart.md, agent-specific template file (e.g., `CLAUDE.md` for Claude Code, `.github/copilot-instructions.md` for GitHub Copilot, `GEMINI.md` for Gemini CLI, `QWEN.md` for Qwen Code or `AGENTS.md` for opencode).
7. Re-evaluate Constitution Check section
   → If new violations: Refactor design, return to Phase 1
   → Update Progress Tracking: Post-Design Constitution Check
8. Plan Phase 2 → Describe task generation approach (DO NOT create tasks.md)
9. STOP - Ready for /tasks command
```

**IMPORTANT**: The /plan command STOPS at step 7. Phases 2-4 are executed by other commands:
- Phase 2: /tasks command creates tasks.md
- Phase 3-4: Implementation execution (manual or via tools)

## Summary
This plan focuses on restoring and verifying the frontend collage editing functionality in the recently modernized Collaged application. The app has been upgraded from Rails 3.2/Backbone.js to Rails 7.2/Hotwire (Turbo + Stimulus), and while the Stimulus controllers have been implemented (grid_controller.js, upload_controller.js, photo_resize_controller.js), the user reports that "frontend collage editing functionality" needs to be "working again."

**Primary Requirements:**
- Restore full photo upload capability (drag-and-drop + file picker)
- Restore photo resizing via edge dragging
- Restore grid layout rendering with aspect ratio preservation
- Ensure all Stimulus controllers properly communicate via events
- Verify CRUD operations work through the Rails 7.2 API

**Technical Approach:**
- Diagnose current state of Stimulus controllers and event wiring
- Verify backend API endpoints return proper JSON responses
- Test Hotwire integration (Turbo Drive, event dispatching)
- Ensure CSRF tokens, Fetch API, and modern browser APIs work correctly
- Validate grid layout algorithm and photo positioning

## Technical Context
**Language/Version**: Ruby 3.3.0, JavaScript (ES6+)
**Primary Dependencies**: Rails 7.2.2, Hotwire (Turbo 8.x, Stimulus 3.x), Mongoid 9.0.x, RMagick 6.x, CarrierWave
**Storage**: MongoDB (collages, photos), SQLite3 (ActiveStorage blobs), File system (image uploads via CarrierWave)
**Testing**: RSpec 6.1, Capybara 3.x, Selenium WebDriver, FactoryBot
**Target Platform**: Modern web browsers (Chrome, Firefox, Safari, Edge), Server: Linux/macOS
**Project Type**: web (Rails monolith with frontend/backend combined)
**Performance Goals**: <100ms page load (NFR-001), 60fps during resize operations (requestAnimationFrame), progressive image loading (NFR-002)
**Constraints**: 10MB max file size, support JPG/PNG/GIF only, no authentication required (GUID-based access)
**Scale/Scope**: Single-page app per collage, unlimited collages, grid layout with 100x100px cells, aspect ratio preservation via prime factorization

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Status**: PASS (no constitution file found at `/Users/bf/.claude/memory/constitution.md`)

Since no project constitution exists, default software engineering best practices apply:
- ✅ Keep it simple (restore existing functionality, no new abstractions)
- ✅ Test-driven approach where practical (leverage existing RSpec/Capybara tests)
- ✅ Follow existing patterns (Stimulus controllers, Rails conventions)
- ✅ Minimize changes (diagnostic fixes only, preserve modernization work)

## Project Structure

### Documentation (this feature)
```
specs/001-awesome-use-the/
├── spec.md              # Feature specification (completed)
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
```
app/
├── controllers/
│   ├── collages_controller.rb    # Collage CRUD + JSON API
│   ├── photos_controller.rb      # Photo CRUD + JSON API
│   ├── root_controller.rb         # Homepage
│   └── application_controller.rb
├── models/
│   ├── collage.rb                 # Mongoid model with GUIDs
│   └── photo.rb                   # Mongoid embedded document
├── views/
│   ├── collages/
│   │   ├── index.html.erb         # Homepage
│   │   ├── new.html.erb           # Create collage form
│   │   └── show.html.erb          # Collage editor (main UI)
│   └── layouts/
│       └── application.html.erb   # Layout with Hotwire includes
├── javascript/
│   ├── application.js             # Importmap entry point
│   └── controllers/
│       ├── grid_controller.js     # Photo grid layout & rendering
│       ├── upload_controller.js   # File upload & drag-and-drop
│       ├── photo_resize_controller.js  # Resize edge dragging
│       ├── collage_form_controller.js  # Create collage form
│       └── helpers/
│           └── math_helpers.js    # Aspect ratio calculations
└── assets/
    └── stylesheets/
        └── application.css        # Sass styles

spec/
├── models/                        # Mongoid model specs
├── requests/                      # API endpoint specs
└── system/                        # Capybara integration tests

config/
├── mongoid.yml                    # MongoDB configuration
├── database.yml                   # SQLite (ActiveStorage)
├── storage.yml                    # CarrierWave storage
└── importmap.rb                   # JavaScript dependencies
```

**Structure Decision**: Rails 7.2 monolith (web application) with:
- Backend: Rails controllers + Mongoid models
- Frontend: Hotwire (Turbo + Stimulus) via Importmap
- Storage: MongoDB (data) + SQLite (ActiveStorage) + filesystem (images)
- Testing: RSpec with request/system specs

## Phase 0: Outline & Research
1. **Extract unknowns from Technical Context** above:
   - For each NEEDS CLARIFICATION → research task
   - For each dependency → best practices task
   - For each integration → patterns task

2. **Generate and dispatch research agents**:
   ```
   For each unknown in Technical Context:
     Task: "Research {unknown} for {feature context}"
   For each technology choice:
     Task: "Find best practices for {tech} in {domain}"
   ```

3. **Consolidate findings** in `research.md` using format:
   - Decision: [what was chosen]
   - Rationale: [why chosen]
   - Alternatives considered: [what else evaluated]

**Output**: research.md with all NEEDS CLARIFICATION resolved

## Phase 1: Design & Contracts
*Prerequisites: research.md complete*

1. **Extract entities from feature spec** → `data-model.md`:
   - Entity name, fields, relationships
   - Validation rules from requirements
   - State transitions if applicable

2. **Generate API contracts** from functional requirements:
   - For each user action → endpoint
   - Use standard REST/GraphQL patterns
   - Output OpenAPI/GraphQL schema to `/contracts/`

3. **Generate contract tests** from contracts:
   - One test file per endpoint
   - Assert request/response schemas
   - Tests must fail (no implementation yet)

4. **Extract test scenarios** from user stories:
   - Each story → integration test scenario
   - Quickstart test = story validation steps

5. **Update agent file incrementally** (O(1) operation):
   - Run `.specify/scripts/bash/update-agent-context.sh claude`
     **IMPORTANT**: Execute it exactly as specified above. Do not add or remove any arguments.
   - If exists: Add only NEW tech from current plan
   - Preserve manual additions between markers
   - Update recent changes (keep last 3)
   - Keep under 150 lines for token efficiency
   - Output to repository root

**Output**: data-model.md, /contracts/*, failing tests, quickstart.md, agent-specific file

## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
- Load `.specify/templates/tasks-template.md` as base
- Generate tasks from Phase 1 design docs (contracts, data model, quickstart)
- Each contract → contract test task [P]
- Each entity → model creation task [P] 
- Each user story → integration test task
- Implementation tasks to make tests pass

**Ordering Strategy**:
- TDD order: Tests before implementation 
- Dependency order: Models before services before UI
- Mark [P] for parallel execution (independent files)

**Estimated Output**: 25-30 numbered, ordered tasks in tasks.md

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Phase 3+: Future Implementation
*These phases are beyond the scope of the /plan command*

**Phase 3**: Task execution (/tasks command creates tasks.md)  
**Phase 4**: Implementation (execute tasks.md following constitutional principles)  
**Phase 5**: Validation (run tests, execute quickstart.md, performance validation)

## Complexity Tracking
*Fill ONLY if Constitution Check has violations that must be justified*

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |


## Phase 2: Task Planning Approach
*This section describes what the /tasks command will do - DO NOT execute during /plan*

**Task Generation Strategy**:
The /tasks command will analyze the diagnostic research findings and generate targeted tasks to restore frontend functionality. Tasks will be organized by investigation area:

1. **Diagnostic Tasks** (identify root cause):
   - Verify Rails server starts and MongoDB connects
   - Test Stimulus controller loading in browser console
   - Inspect API endpoint JSON responses
   - Check browser console for JavaScript errors
   - Verify CSS loading and grid layout styles
   - Test CSRF token presence in meta tags
   - Check Turbo Drive configuration

2. **Fix Tasks** (based on findings):
   - Fix importmap configuration if controllers not loading
   - Add/fix CSRF token handling if API calls fail
   - Configure Turbo Drive (add data-turbo="false" if interfering)
   - Fix ObjectId JSON serialization if photos don't render
   - Fix CSS loading if grid layout is broken
   - Fix event communication if controllers don't communicate

3. **Verification Tasks** (confirm fixes work):
   - Test collage creation end-to-end
   - Test photo upload (file picker + drag-and-drop)
   - Test photo rendering in grid
   - Test photo resize interaction
   - Test grid re-flow after resize
   - Run existing RSpec/Capybara tests

**Ordering Strategy**:
1. **Investigation first**: Run all diagnostic tasks to identify root cause
2. **Fix in order of likelihood**: Based on common post-migration issues (importmap → CSRF → Turbo → ObjectId → CSS)
3. **Verify after each fix**: Test specific functionality before moving to next fix
4. **Regression testing**: Run full test suite after all fixes applied

**Dependencies**:
- Diagnostic tasks are parallel (can run all at once)
- Fix tasks are sequential (must identify issue before fixing)
- Verification tasks depend on fixes being applied

**Estimated Output**: 15-20 tasks covering diagnostic → fix → verify workflow

**IMPORTANT**: This phase is executed by the /tasks command, NOT by /plan

## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) - ✅ research.md with diagnostic guidance
- [x] Phase 1: Design complete (/plan command) - ✅ data-model.md, contracts/, quickstart.md exist
- [x] Phase 2: Task planning complete (/plan command - describe approach only) - ✅ Strategy documented above
- [x] Phase 3: Tasks generated (/tasks command) - ✅ tasks.md with 35 diagnostic/fix/verification tasks
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS (no constitution file, using best practices)
- [x] Post-Design Constitution Check: PASS (existing design follows Rails/Hotwire patterns)
- [x] All NEEDS CLARIFICATION resolved (Technical Context filled, research complete)
- [x] Complexity deviations documented (N/A - no constitution violations)

**Artifacts Generated**:
- ✅ `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/plan.md` (this file)
- ✅ `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/research.md` (Phase 0)
- ✅ `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/data-model.md` (Phase 1)
- ✅ `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/quickstart.md` (Phase 1)
- ✅ `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/contracts/collaged-api.yaml` (Phase 1)
- ✅ `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/tasks.md` (exists, ready for /tasks command)

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md` (not found, using defaults)*
