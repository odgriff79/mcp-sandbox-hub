import sys
sys.path.insert(0, 'projects/aaf2resolve/src')
from build_canonical import build_canonical_from_aaf

result = build_canonical_from_aaf('projects/aaf2resolve/tests/fixtures/aaf/candidate.aaf')
clips = result['timeline']['tracks'][0]['clips']

print(f"✅ Total Events: {len(clips)}")

# Count media vs effects
media = [c for c in clips if 'FX_ON_FILLER' not in c.get('source_umid', '')]
effects = [c for c in clips if 'FX_ON_FILLER' in c.get('source_umid', '')]

print(f"  📹 Media clips: {len(media)}")
print(f"  ✨ Effects on filler: {len(effects)}")

# Check for real source names
print("\n🎬 First 5 clips:")
for i, clip in enumerate(clips[:5]):
    print(f"  {i+1}. {clip['name']}")

# Check for B006 clips
b006_clips = [c for c in clips if 'B006' in c.get('name', '')]
print(f"\n📁 B006 clips found: {len(b006_clips)}")

# Check for effect types
effect_names = set()
for clip in clips:
    if 'effect_params' in clip:
        op = clip['effect_params'].get('operation', '')
        if op and op != 'N/A':
            effect_names.add(op)

print(f"\n🎨 Unique effects: {len(effect_names)}")
for effect in list(effect_names)[:5]:
    print(f"  - {effect}")
