# Full Context Brief: AAF2Resolve + Agent-MCP Integration
Date: 2025-01-04
Type: PROJECT_MERGER_MILESTONE

## Repository Structure
- **Primary Workspace**: C:\Users\o_gri\REPO\mcp-sandbox-hub
- **AAF Project Mirror**: projects/aaf2resolve-spec-mirror (complete clone)
- **Active Development**: projects/aaf2resolve/src/

## AAF2Resolve Project Status

### Last Major Breakthrough (2025-09-03T17:20Z)
**Version**: PARSER_RULES:v20250903-1720:use-mob-and-mob_id-attributes

**Key Fixes Implemented**:
1. **Deep Traversal Fixed**: Use `segments` not `input_segments` for OperationGroup traversal
2. **Source Resolution Fixed**: Use `SourceClip.mob` and `SourceClip.mob_id` attributes directly  
3. **Depth 4 Traversal**: Successfully navigating OperationGroup → segments → Sequence → components → SourceClip

### Current Achievements
✅ **71 Events Extracted** (Target: 71)
  - 35 Media+Effect events (combined clips with effects)
  - 36 FX-only events (effects on filler/gaps)

✅ **Source Resolution Working**
  - Real clip names: B006_C020_012989_001.new.01, etc.
  - Valid UMIDs: urn:smpte:umid:060a2b34.01010105.01010f10.13000000...
  - All 35 media clips properly resolved

✅ **Effect Extraction Working**  
  - Real effect names captured:
    - AVX2 Effect : EFF2_BLEND_RESIZE (58 parameters)
    - AVX2 Effect : EFF2_STABILIZE (4 parameters)
    - Image : EFF_SUBMASTER (9 parameters)

### Pending Work
⚠️ **Animated Parameters**: 603 detected via traces but not yet stored in final JSON output
⚠️ **FCPXML Writer**: Needs completion for Resolve import
⚠️ **Keyframe Timing**: Conversion from AAF normalized (0.0-1.0) to FCPXML seconds

## Agent-MCP Integration Goals

### Multi-Agent Strategy
1. **Parser Agent** (Claude): Complete animated parameter storage
2. **FCPXML Agent** (GPT-4): Map effects to Resolve-compatible format
3. **Test Agent**: Validate 71-event extraction continuously
4. **Coordinator**: Ensure canonical JSON contract maintained

### Test Target
- **File**: candidate.aaf (need to upload)
- **Expected Output**: 71 events, 603 animated parameters
- **Validation**: Import to DaVinci Resolve without errors

## Technical Context

### Working Parser Core (build_canonical.py)
- Lines 707-759: Fixed deep traversal using `segments`
- Lines 763-814: Direct mob/mob_id attribute access
- Lines 99-166: Keyframe extraction with rational handling

### Multiple Parser Versions Available
- build_canonical.py (current working version)
- build_canonical_fixed.py (attempted VaryingValue fix)
- build_canonical_with_parameters.py (parameter extraction focus)
- 5 backup versions tracking evolution

### Key Functions Working
- `_find_nested_source_clip_deep()`: Proper traversal
- `_process_source_clip()`: Source resolution via mob attributes
- `extract_fcpxml_relevant_parameters()`: Parameter extraction

## Next Steps for Agents

### Immediate Tasks
1. Store the 603 animated parameters in JSON output
2. Complete FCPXML writer with effect mapping
3. Upload candidate.aaf for testing
4. Set up automated validation pipeline

### Agent Deployment Plan
- Use GitHub Codespaces for cloud execution
- Agents work autonomously on different aspects
- Coordinate through canonical JSON schema
- Validate against 71-event target continuously

## File Inventory
- **Source Code**: 13 Python files in projects/aaf2resolve/src/
- **Documentation**: Complete specs in projects/aaf2resolve/docs/specs/
- **Memory Notes**: Historical context from both Claude and GPT sessions
- **Test Files**: Need candidate.aaf and candidate.csv

## Success Metrics
- [x] 71 events extracted
- [x] 35/35 sources resolved  
- [x] Effect names correct
- [x] Parameters detected
- [ ] Animated parameters in output
- [ ] FCPXML generation working
- [ ] Resolve import successful

---
This milestone represents the convergence of:
1. A working AAF parser (breakthrough achieved)
2. Agent-MCP infrastructure (ready for deployment)
3. Clear path to completion via multi-agent collaboration

The parser core is FUNCTIONALLY COMPLETE for detection and resolution.
Remaining work is output formatting and FCPXML conversion.
