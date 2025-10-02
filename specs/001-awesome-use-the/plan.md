
# Implementation Plan: Restore Photo Drag-and-Drop Reordering

**Branch**: `001-awesome-use-the` | **Date**: 2025-10-01 | **Spec**: [spec.md](spec.md)
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
**Issue Identified**: User observation "looks like we lost drag and drop reorder!" after Rails 7.2 modernization.

**Critical Discovery**: After reviewing legacy Backbone.js code (see LEGACY_ANALYSIS.md), photo reordering was **never fully implemented** in the original system. The frontend had a `handle_move()` placeholder that only logged mouse coordinates without any reordering logic. This is **new functionality**, not restoration.

**Backend State**:
- ✅ Photo.ordinal field exists with index
- ✅ Controller permits ordinal updates
- ✅ Photos sorted by ordinal on load
- ❌ Frontend never updated ordinals for reordering (neither legacy nor current)

**Primary Requirement**: Implement (not restore) the ability to reorder photos within a collage using drag-and-drop interaction, completing the unfinished infrastructure from the legacy system while maintaining 60fps performance and all existing resize functionality.

**Technical Approach**: Implement a new Stimulus controller for drag-and-drop reordering that works alongside the existing photo-resize controller, using the HTML5 Drag and Drop API with ordinal field updates persisted to the server. This completes the original architectural intent evidenced by the prepared backend ordinal field.

## Technical Context
**Language/Version**: Ruby 3.3.0, JavaScript ES6+ (Rails 7.2.2 application)
**Primary Dependencies**: Hotwire (Turbo 8.x, Stimulus 3.x), Mongoid 9.0.x, RMagick 6.x, CarrierWave
**Storage**: MongoDB (collages, photos with ordinal field), SQLite3 (ActiveStorage blobs), File system (image uploads)
**Testing**: RSpec 6.1 with Capybara 3.x for system tests, performance specs for drag-and-drop validation
**Target Platform**: Modern web browsers (Chrome, Firefox, Safari) with HTML5 Drag and Drop API support
**Project Type**: Web application (Rails backend + JavaScript frontend with Hotwire)
**Performance Goals**: 60fps during drag operations (<16.67ms per frame), <100ms page load for collage display
**Constraints**: Must preserve existing photo resize functionality, maintain grid-based layout system, support concurrent editing (last-write-wins)
**Scale/Scope**: Single-page collage editing interface, affects grid_controller.js and photos collection rendering, estimated 3-5 new functions

## Constitution Check
*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### I. Feature Preservation ✅ PASS
- **Status**: COMPLIANT - This change RESTORES a lost feature from the legacy system
- **Evidence**: Photo model has `ordinal` field (photo.rb:7-8), controller permits ordinal updates (photos_controller.rb:102), but no frontend drag-and-drop UI exists
- **Impact**: Restores functionality that existed in the Backbone.js implementation but was lost during Hotwire migration

### II. Incremental Modernization ✅ PASS
- **Status**: COMPLIANT - Small, isolated change to JavaScript controllers
- **Approach**: Add new drag-and-drop controller alongside existing photo-resize controller without modifying backend
- **Rollback**: Can be easily removed by deleting new controller and reverting view changes

### III. Test Coverage Before Changes ✅ PASS
- **Status**: COMPLIANT - Characterization test exists (spec/performance/drag_drop_spec.rb)
- **Action**: Implement the skipped performance test before adding drag-and-drop functionality
- **Coverage**: Will add integration tests for ordinal updates and system tests for drag interaction

### IV. Technology Stack Modernization ✅ PASS
- **Status**: COMPLIANT - Uses Stimulus (modern framework) with HTML5 Drag and Drop API
- **Rationale**: Follows established Hotwire patterns used in photo-resize controller
- **Consistency**: Matches architecture decisions from completed Rails 7.2 upgrade

### V. Data Integrity ✅ PASS
- **Status**: COMPLIANT - No schema changes required
- **Evidence**: Ordinal field already exists in Photo model with index
- **Safety**: Updates use existing PATCH endpoint with strong parameter validation

### VI. Performance Preservation ✅ PASS
- **Status**: COMPLIANT - Must match or exceed legacy drag performance
- **Target**: 60fps (< 16.67ms per frame) per NFR-001 and existing performance spec
- **Validation**: Use requestAnimationFrame throttling like photo-resize controller

### VII. Documentation and Knowledge Transfer ✅ PASS
- **Status**: COMPLIANT - This plan documents the gap and restoration approach
- **Context**: Captures that ordinal field exists but drag UI was lost during modernization
- **Knowledge**: Documents interaction between drag-and-drop and resize controllers

## Project Structure

### Documentation (this feature)
```
specs/001-awesome-use-the/
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
│   └── photos_controller.rb          # Existing: permits ordinal parameter
├── models/
│   ├── collage.rb                     # Existing: embeds photos
│   └── photo.rb                       # Existing: has ordinal field with index
├── views/
│   └── collages/
│       └── show.html.erb              # To be modified: add drag-and-drop attributes
├── javascript/
│   └── controllers/
│       ├── grid_controller.js         # To be modified: add drag event handling
│       ├── photo_resize_controller.js # Existing: handles resize operations
│       └── photo_reorder_controller.js # NEW: handles drag-and-drop reordering
└── assets/
    └── stylesheets/
        └── collages.scss              # To be modified: add drag cursor styles

spec/
├── models/
│   └── photo_spec.rb                  # Existing: validates ordinal field
├── requests/
│   └── photos_update_spec.rb          # Existing: tests PATCH with ordinal
├── system/
│   └── photo_reorder_spec.rb          # NEW: drag-and-drop system tests
└── performance/
    └── drag_drop_spec.rb              # Existing but skipped: implement tests
```

**Structure Decision**: Rails monolith with Hotwire frontend. JavaScript controllers live in `app/javascript/controllers/`, models in `app/models/`, specs in `spec/`. This follows standard Rails 7.2 conventions with Stimulus controllers for frontend interactivity.

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
Since the Photo model and photos_controller already exist with ordinal field support, the /tasks command will generate tasks focused on frontend restoration:

1. **Test Setup Tasks** (from skipped performance test):
   - Implement spec/performance/drag_drop_spec.rb [P]
   - Add system test: spec/system/photo_reorder_spec.rb [P]
   - Add Stimulus controller test: spec/javascript/photo_reorder_controller_spec.js [P]

2. **Implementation Tasks** (TDD order):
   - Create photo_reorder_controller.js (new Stimulus controller)
   - Add drag event handlers (dragstart, dragover, drop, dragend)
   - Implement ordinal update logic
   - Add visual feedback styles (CSS)
   - Update grid_controller.js to listen for reorder events
   - Update collages/show.html.erb to add draggable attributes

3. **Integration Tasks**:
   - Wire photo_reorder_controller to photo elements
   - Connect reorder controller to grid controller via events
   - Add CSRF token handling for PATCH requests
   - Test resize + reorder interaction (no conflicts)

4. **Validation Tasks**:
   - Run quickstart validation (Scenario 7)
   - Performance test: verify 60fps during drag
   - Accessibility test: keyboard navigation
   - Cross-browser test: Chrome, Firefox, Safari

**Ordering Strategy**:
- Tests first (TDD): performance spec → system spec → controller spec → implementation
- Core functionality: photo_reorder_controller → CSS styles → view updates
- Integration: event wiring → grid reflow → CSRF handling
- Validation: manual testing → performance → accessibility
- Mark [P] for parallel test creation (independent spec files)

**Estimated Output**: 15-20 numbered, ordered tasks in tasks.md

**Dependencies**:
- No backend changes needed (ordinal field exists, controller permits it)
- No data migrations needed (Photo model already has ordinal with index)
- Builds on existing grid_controller.js and photo_resize_controller.js patterns

**Key Design Decisions from Research**:
- HTML5 Drag and Drop API (native browser support)
- Separate photo_reorder_controller.js (single responsibility)
- Recalculate all ordinals sequentially after drag
- requestAnimationFrame throttling for 60fps performance
- Last-write-wins for concurrent edits (matches FR-040)

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


## Progress Tracking
*This checklist is updated during execution flow*

**Phase Status**:
- [x] Phase 0: Research complete (/plan command)
  - research.md created with comprehensive drag-and-drop analysis
  - 6 research questions answered with decisions and rationale
  - Technology choices documented (HTML5 Drag and Drop API, Stimulus architecture)
- [x] Phase 1: Design complete (/plan command)
  - data-model.md: Photo model with ordinal field documented
  - contracts/photo_reorder.yml: OpenAPI 3.0 contract created
  - quickstart.md: Scenario 7 (photo reordering validation) added
  - CLAUDE.md: Updated with drag-and-drop context
- [x] Phase 2: Task planning approach described (/plan command - describe approach only)
  - Task generation strategy documented
  - Ordering strategy defined (TDD, tests first)
  - Estimated 15-20 tasks for frontend-only implementation
- [ ] Phase 3: Tasks generated (/tasks command) - **NEXT STEP**
- [ ] Phase 4: Implementation complete
- [ ] Phase 5: Validation passed

**Gate Status**:
- [x] Initial Constitution Check: PASS (all 7 principles compliant)
- [x] Post-Design Constitution Check: PASS (no violations, no complexity deviations)
- [x] All NEEDS CLARIFICATION resolved (none in Technical Context)
- [x] Complexity deviations documented (none - table empty)

**Artifacts Generated**:
- ✅ /Users/bf/Code/claude/collaged/specs/001-awesome-use-the/plan.md (this file)
- ✅ /Users/bf/Code/claude/collaged/specs/001-awesome-use-the/research.md (updated with addendum)
- ✅ /Users/bf/Code/claude/collaged/specs/001-awesome-use-the/data-model.md (existing, validated)
- ✅ /Users/bf/Code/claude/collaged/specs/001-awesome-use-the/contracts/photo_reorder.yml (new)
- ✅ /Users/bf/Code/claude/collaged/specs/001-awesome-use-the/quickstart.md (updated with Scenario 7)
- ✅ /Users/bf/Code/claude/collaged/CLAUDE.md (updated with drag-and-drop context)
- ⏳ /Users/bf/Code/claude/collaged/specs/001-awesome-use-the/tasks.md (generated by /tasks command)

**Ready for**: `/tasks` command to generate implementation task list

---
*Based on Constitution v1.0.0 - See `.specify/memory/constitution.md`*
