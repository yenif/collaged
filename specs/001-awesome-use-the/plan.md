
# Implementation Plan: Collaged Full Dependency Modernization

**Branch**: `001-awesome-use-the` | **Date**: 2025-09-30 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/Users/bf/Code/claude/collaged/specs/001-awesome-use-the/spec.md`

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
Modernize Collaged photo collage application from Rails 3.2.14 (2013) + Backbone.js to current technology stack while preserving all existing features: collage creation, multi-photo upload with drag-and-drop, grid-based layout with automatic aspect ratio preservation, photo resizing, and GUID-based access control (read-only vs read-write URLs). This is a comprehensive dependency modernization addressing 10+ year old stack with known security vulnerabilities.

**User-facing requirements**: Full feature parity with current system including <100ms page load, progressive image loading, duplicate detection, last-write-wins concurrent editing, and user-initiated deletion.

## Technical Context
**Current Stack (Legacy)**:
- Ruby 1.9.2 + Rails 3.2.14
- Backbone.js + Underscore.js + jQuery
- MongoDB + Mongoid 3.x ODM
- RMagick for image processing
- Plupload for file uploads
- RSpec 2.14 + Cucumber + Capybara for testing

**Language/Version**: NEEDS CLARIFICATION (Ruby 3.3.x + Rails 7.x OR Node.js + modern framework)
**Primary Dependencies**: NEEDS CLARIFICATION (Rails upgrade path vs full rewrite; React/Vue/Svelte vs Hotwire)
**Storage**: MongoDB (preserve existing data structures; consider Mongoid 9.x upgrade)
**Image Processing**: NEEDS CLARIFICATION (MiniMagick/ImageProcessing vs cloud-based transcoding)
**File Upload**: NEEDS CLARIFICATION (ActiveStorage, Uppy.js, or native HTML5)
**Testing**: NEEDS CLARIFICATION (RSpec 6.x + Capybara 3.x OR Jest/Vitest + Playwright)
**Target Platform**: Web application (browser-based, server-rendered or SPA)
**Project Type**: web (frontend + backend)
**Performance Goals**: <100ms page load (structure + layout), progressive image loading, 60fps drag-and-drop interactions
**Constraints**: 10MB per file upload, maintain GUID-based access control, preserve MongoDB schema/data
**Scale/Scope**: Small-to-medium modernization project (~10k LOC legacy codebase); focus on dependency updates and security, not feature additions

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**I. Feature Preservation** ✅ PASS
- All 53 functional requirements from spec must be preserved
- Creating collages, uploading photos, grid layout, resizing, access control, deletion
- Characterization tests required before any changes

**II. Incremental Modernization** ✅ PASS
- Planned approach: dependency upgrades → backend → frontend → polish
- Each phase maintains functional application
- Can pause at any checkpoint

**III. Test Coverage Before Changes** ✅ PASS
- Phase 0 includes characterization test strategy
- Existing RSpec/Cucumber tests → document current behavior
- New tests required before modernizing each component

**IV. Technology Stack Modernization** ⚠️ NEEDS RESEARCH
- Multiple viable paths (Rails upgrade vs rewrite, frontend framework choice)
- Phase 0 research will evaluate: maintainability, migration complexity, performance, community support
- Decision criteria documented in research.md

**V. Data Integrity** ✅ PASS
- MongoDB schema preservation required
- Collage and Photo entities with existing relationships maintained
- Migration scripts with rollback for any schema changes

**VI. Performance Preservation** ✅ PASS
- Spec requires <100ms page load (matches/exceeds legacy if properly implemented)
- Progressive image loading maintains responsiveness
- Drag-and-drop 60fps target

**VII. Documentation and Knowledge Transfer** ✅ PASS
- This plan.md documents approach
- research.md will capture legacy behavior and decisions
- quickstart.md will validate feature preservation

**Initial Gate Status**: PASS with research phase required to resolve technology choices

## Project Structure

### Documentation (this feature)
```
specs/[###-feature]/
├── plan.md              # This file (/plan command output)
├── research.md          # Phase 0 output (/plan command)
├── data-model.md        # Phase 1 output (/plan command)
├── quickstart.md        # Phase 1 output (/plan command)
├── contracts/           # Phase 1 output (/plan command)
└── tasks.md             # Phase 2 output (/tasks command - NOT created by /plan)
```

### Source Code (repository root)
**Current Legacy Structure** (Rails 3.2 monolith):
```
app/
├── assets/
│   ├── javascripts/       # Backbone.js models, views, routers
│   │   ├── models/        # Collage, Photo models
│   │   ├── views/         # CollageShow, PhotoView, etc.
│   │   ├── routers/       # AppRouter
│   │   └── lib/           # Backbone, Underscore, Plupload
│   └── stylesheets/
├── controllers/           # CollagesController, PhotosController, RootController
├── models/                # Collage, Photo (Mongoid models)
├── uploaders/             # ImageUploader (CarrierWave)
├── helpers/               # Templater helper
└── views/                 # ERB templates

config/                    # Rails config, routes, initializers
spec/                      # RSpec tests
features/                  # Cucumber feature tests
test/                      # Test fixtures
```

**Target Modern Structure** (to be determined in Phase 0 research):
```
# Option A: Rails 7.x monolith with modern frontend
app/
├── controllers/           # Modern Rails 7.x controllers
├── models/                # Mongoid 9.x models
├── javascript/            # Modern JS (Hotwire/Stimulus OR React/Vue)
│   ├── controllers/       # Stimulus controllers OR
│   ├── components/        # React/Vue components
│   └── lib/
├── views/                 # ERB/ViewComponents
└── uploaders/             # ActiveStorage or CarrierWave

# Option B: API + SPA separation
backend/
├── app/
│   ├── controllers/api/   # JSON API controllers
│   ├── models/            # Mongoid models
│   └── services/          # Business logic
└── spec/

frontend/
├── src/
│   ├── components/        # React/Vue/Svelte components
│   ├── pages/             # Route pages
│   ├── services/          # API client
│   └── lib/               # Grid layout, drag-drop utilities
└── tests/
```

**Structure Decision**: Web application (backend + frontend). Final choice between Rails monolith vs API+SPA separation will be documented in research.md Phase 0 based on: migration complexity, team expertise, maintenance burden, and performance characteristics.

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
The `/tasks` command will create a dependency-ordered task list for incremental Rails modernization:

**Phase-Based Task Structure**:
1. **Characterization Phase** (P0 - before any changes):
   - Document current behavior via tests
   - Run existing RSpec + Cucumber suites
   - Create coverage reports
   - Tasks: 5-7 parallel characterization tasks

2. **Foundation Upgrade Phase** (P1 - critical path):
   - Ruby 1.9.2 → 3.3.x
   - Rails 3.2 → 4.2 → 5.2 → 6.1 → 7.2 (incremental)
   - Mongoid 3.x → 9.x migration
   - Each Rails version: test suite validation task
   - Tasks: ~15-20 sequential upgrade tasks with checkpoints

3. **Backend Modernization** (P2 - after Rails 7.x stable):
   - CarrierWave → ActiveStorage migration (data-model.md rake task)
   - RMagick → ImageProcessing + libvips
   - UUIDTools → SecureRandom (code changes only)
   - Contract test implementation (from contracts/collaged-api.yaml)
   - Tasks: 8-10 tasks, some parallel [P]

4. **Frontend Modernization** (P3 - after backend stable):
   - Backbone.js → Hotwire Turbo Drive (page transitions)
   - Backbone Views → Stimulus controllers (drag-drop, resize)
   - Plupload → ActiveStorage Direct Upload
   - jQuery → Stimulus actions
   - Underscore → ES6+ native methods
   - Tasks: 10-12 sequential tasks (JS framework transition)

5. **Testing Infrastructure** (P4 - parallel with frontend):
   - RSpec 2.14 → 6.x upgrade
   - Cucumber → RSpec system tests migration
   - Capybara 0.4 → 3.x with Selenium
   - Remove Akephalos, Spork, Turn
   - Add performance benchmarks (<100ms, 60fps)
   - Tasks: 6-8 tasks, mostly parallel [P]

6. **Validation & Polish** (P5 - final):
   - Execute quickstart.md validation scenarios
   - Performance regression tests
   - Security audit (dependency scan)
   - Documentation updates
   - Deploy to staging
   - Tasks: 5-6 validation tasks

**Ordering Strategy**:
- Sequential by phase: P0 → P1 → P2 → P3 → P4 → P5
- Within phase: Mark [P] for independent tasks
- TDD pattern: Test tasks before implementation tasks
- Checkpoints: After each Rails version upgrade, run full test suite
- Rollback points: After each phase, tag commit for easy revert

**Dependency Graph**:
```
P0 (Characterization) ━━━━┓
                           ┣━━━▶ P1 (Ruby/Rails) ━━━━┓
                           ┃                           ┣━━▶ P2 (Backend) ━━┓
                           ┃                           ┃                    ┃
                           ┗━━━━━━━━━━━━━━━━━━━━━━━━━━┫                    ┣━▶ P5 (Validation)
                                                       ┃                    ┃
                                                       ┗━━▶ P3 (Frontend) ━┫
                                                       ┗━━▶ P4 (Testing) ━━┛
```

**Estimated Output**: 50-65 numbered, dependency-ordered tasks in tasks.md
**Actual Output**: 62 numbered tasks (within estimated range)

**Task Template Per Phase**:
- Phase header with context
- Tasks numbered globally (001, 002, ...)
- Each task: Description, Acceptance Criteria, Test Command, Rollback Steps
- [P] marker for parallelizable tasks
- Constitutional principle reference (feature preservation, incremental, etc.)

**IMPORTANT**: This phase is executed by the `/tasks` command, NOT by `/plan`

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


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command) - research.md created
- [x] Phase 1: Design complete (/plan command) - data-model.md, contracts/, quickstart.md, CLAUDE.md
- [x] Phase 2: Task planning complete (/plan command - approach described, ready for /tasks)
- [ ] Phase 3: Tasks generated (/tasks command)
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS
- [x] Post-Design Constitution Check: PASS (see below)
- [x] All NEEDS CLARIFICATION resolved - See research.md
- [x] Complexity deviations documented - None (incremental approach fits constitution)

**Post-Design Constitution Re-Check**:
- ✅ Feature Preservation: data-model.md preserves all entities, quickstart.md validates all 53 FRs
- ✅ Incremental Modernization: Phase 2 plan shows 6 sequential phases with checkpoints
- ✅ Test Coverage: Characterization phase (P0) before any changes, quickstart.md validation
- ✅ Technology Stack: Research decisions documented with rationale (Rails 7.x + Hotwire)
- ✅ Data Integrity: MongoDB schema preservation, migration scripts with rollback
- ✅ Performance: NFR targets specified in quickstart.md (<100ms, 60fps); NFR-003 fulfilled via ActiveStorage variants (thumbnailing AND format transcoding)
- ✅ Documentation: All design artifacts complete, agent context updated

---
*Based on Constitution v2.1.1 - See `/memory/constitution.md`*
