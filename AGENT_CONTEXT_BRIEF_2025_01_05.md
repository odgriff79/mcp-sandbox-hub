AAF2Resolve Multi-Agent Autonomous Development Context Brief
Date: 2025-01-05
Type: PROJECT_HANDOFF_FOR_AUTONOMOUS_AGENTS
Priority: ENABLE FULLY AUTONOMOUS MULTI-AGENT DEVELOPMENT - NO LOCAL EXECUTION
🎯 Mission Statement
Enable multiple AI agents to autonomously complete the AAF to FCPXML conversion pipeline WITHOUT requiring local machine code execution. All work should happen in GitHub Codespaces or through cloud-based development.
📍 Repository Location
•GitHub: https://github.com/odgriff79/mcp-sandbox-hub
•Primary Project Path: /projects/aaf2resolve/
•Working Parser: /projects/aaf2resolve/src/build_canonical.py
✅ Current Working Status (VERIFIED 2025-01-05)
Parser Functionality - CONFIRMED WORKING
✅ Total Events: 71 (CORRECT)
  📹 Media clips: 35 (CORRECT)
  ✨ Effects on filler: 36 (CORRECT)
Successfully Extracting
•Real clip names: B006_C020_012989_001.new.01, A004_C020_0430NW.new.01, etc.
•Real effect names: AVX2 Effect : EFF2_BLEND_RESIZE, EFF2_STABILIZE, EFF_SUBMASTER
•Unique effects: 25 different effect types identified
•B006 clips: 6 found and properly named
🔴 Critical Issue to Fix
Animated Parameters Not Stored in JSON Output
•603 animated parameters are DETECTED (visible in traces)
•Problem: They're not being written to the final JSON output
•Location: extract_keyframe_timing_data() function works but results aren't persisted
•Impact: FCPXML can't access the keyframe data it needs
📂 Repository Structure
mcp-sandbox-hub/
├── projects/
│   ├── aaf2resolve/          # ACTIVE DEVELOPMENT
│   │   ├── src/              
│   │   │   ├── build_canonical.py         # ✅ WORKING (71 events)
│   │   │   ├── build_canonical_fixed.py   # Attempted VaryingValue fix
│   │   │   ├── write_fcpxml.py           # Needs completion
│   │   │   └── [5 backup versions]       # Historical attempts
│   │   ├── tests/
│   │   │   └── fixtures/aaf/
│   │   │       ├── candidate.aaf         # ✅ 7.6MB test file
│   │   │       └── candidate_legacy.csv  # Expected outputs
│   │   └── docs/specs/       # Complete documentation
│   └── aaf2resolve-spec-mirror/  # Reference copy
└── AGENT_CONTEXT_BRIEF_2025_01_05.md  # THIS FILE
🔧 Technical Details for Agents
Working Parser Version
•File: build_canonical.py
•Version Tag: PARSER_RULES:v20250903-1720:use-mob-and-mob_id-attributes
•Key Fixes: 
oLine 707-759: Deep traversal using segments (NOT input_segments)
oLine 763-814: Direct mob and mob_id attribute access
oLine 99-166: Keyframe extraction with rational handling
The 603 Parameter Problem
# This DETECTS parameters correctly:
def extract_keyframe_timing_data(param):
    # Successfully identifies VaryingValue with PointList
    # Returns keyframe data structure
    
# But this doesn't STORE them in output:
def extract_fcpxml_relevant_parameters(operation_group):
    # Calls extract_keyframe_timing_data
    # But returned keyframes aren't added to final JSON
🎯 Agent Tasks Priority Order
1. Parameter Storage Fix (HIGHEST PRIORITY)
•Make the 603 animated parameters appear in JSON output
•Modify extract_fcpxml_relevant_parameters() to store keyframe data
•Verify with: parameters should have "type": "animated" with keyframes array
2. FCPXML Writer Completion
•Map canonical JSON to FCPXML 1.11 format
•Handle both static and animated parameters
•Ensure Resolve compatibility
3. Test Automation
•All tests should run in Codespaces
•Validate 71 events continuously
•Check parameter counts
🚀 How Agents Should Work
Setup in GitHub Codespaces
# Agents should:
1. Open repo in Codespaces
2. cd /workspaces/mcp-sandbox-hub
3. pip install pyaaf2
4. Run tests: python projects/aaf2resolve/tests/run_tests.py
Validation Command
# Agents can verify parser works with:
python -c "from projects.aaf2resolve.src.build_canonical import build_canonical_from_aaf; result = build_canonical_from_aaf('projects/aaf2resolve/tests/fixtures/aaf/candidate.aaf'); clips = result['timeline']['tracks'][0]['clips']; print(f'Events: {len(clips)}')"
# Should output: Events: 71
📊 Success Metrics
•✅ 71 events in output (ALREADY WORKING)
•✅ 35 media + 36 effects (ALREADY WORKING)
•❌ 603 animated parameters in JSON (NEEDS FIX)
•❌ FCPXML imports to Resolve (NEEDS COMPLETION)
🤖 Multi-Agent Collaboration Strategy
Agent Roles
1.Parser Agent: Fix parameter storage issue
2.FCPXML Agent: Complete writer implementation
3.Test Agent: Continuous validation
4.Coordinator Agent: Ensure changes don't break 71-event extraction
Key Rule for Agents
NO LOCAL EXECUTION - All code runs in Codespaces or cloud environments. The human user (o_gri) should not need to run any code locally.
📝 Historical Context
•September 3, 2024: Major breakthrough fixing deep traversal
•January 4, 2025: Repository consolidated and tested
•January 5, 2025: Confirmed 71 events working, ready for autonomous agents
⚠️ Critical Warnings for Agents
1.DO NOT BREAK THE 71-EVENT EXTRACTION - It's working correctly
2.USE segments NOT input_segments for OperationGroup traversal
3.USE mob and mob_id attributes for source resolution
4.TEST EVERY CHANGE against candidate.aaf
📞 Communication Protocol
•Agents should commit with clear messages
•Use PR descriptions to explain changes
•Tag commits with [PARAM-FIX], [FCPXML], [TEST] prefixes
•Create issues for blockers
🎯 End Goal
A fully automated AAF → FCPXML pipeline that:
1.Extracts all 71 events ✅
2.Captures all 603 animated parameters ❌ (PRIORITY FIX)
3.Generates valid FCPXML ❌ (NEXT)
4.Imports successfully into DaVinci Resolve ❌ (FINAL VALIDATION)
________________________________________
This brief should be the FIRST thing any new agent reads when joining the project.
