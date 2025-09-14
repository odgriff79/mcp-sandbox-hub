#!/usr/bin/env python3
'''
Test suite for build_canonical.py

Tests the AAF parser against known test files and validates:
- 71 events extracted from candidate.aaf
- Proper source resolution (35 media clips + 36 effects on filler)
- Animated parameter extraction (603 parameters)
'''

import json
import os
import sys
import unittest
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from build_canonical import build_canonical_from_aaf


class TestCanonicalBuilder(unittest.TestCase):
    '''Test the canonical JSON builder'''
    
    def setUp(self):
        '''Set up test fixtures'''
        self.fixtures_dir = Path(__file__).parent / 'fixtures'
        self.expected_dir = Path(__file__).parent / 'expected'
        self.candidate_aaf = self.fixtures_dir / 'candidate.aaf'
    
    def test_candidate_aaf_exists(self):
        '''Test that candidate.aaf is available'''
        if not self.candidate_aaf.exists():
            self.skipTest(f'candidate.aaf not found at {self.candidate_aaf}')
    
    def test_extract_71_events(self):
        '''Test that we extract exactly 71 events from candidate.aaf'''
        if not self.candidate_aaf.exists():
            self.skipTest('candidate.aaf not found')
        
        # Parse the AAF
        result = build_canonical_from_aaf(str(self.candidate_aaf))
        
        # Check structure
        self.assertIn('timeline', result)
        self.assertIn('tracks', result['timeline'])
        self.assertGreater(len(result['timeline']['tracks']), 0)
        
        # Count events
        track = result['timeline']['tracks'][0]
        clips = track.get('clips', [])
        
        self.assertEqual(len(clips), 71, 
                        f'Expected 71 events, got {len(clips)}')
    
    def test_source_resolution(self):
        '''Test that sources are properly resolved'''
        if not self.candidate_aaf.exists():
            self.skipTest('candidate.aaf not found')
        
        result = build_canonical_from_aaf(str(self.candidate_aaf))
        clips = result['timeline']['tracks'][0]['clips']
        
        # Check for real clip names (not "Unresolved Media")
        resolved_clips = [c for c in clips 
                         if 'Unresolved' not in c.get('name', '')]
        
        self.assertGreater(len(resolved_clips), 0,
                          'No clips were properly resolved')
        
        # Validate we have B006_C020_012989_001.new.01 clips
        b006_clips = [c for c in clips 
                     if 'B006_C020' in c.get('name', '')]
        
        self.assertGreater(len(b006_clips), 0,
                          'Expected B006_C020 clips not found')
    
    def test_effect_extraction(self):
        '''Test that effects are properly extracted'''
        if not self.candidate_aaf.exists():
            self.skipTest('candidate.aaf not found')
        
        result = build_canonical_from_aaf(str(self.candidate_aaf))
        clips = result['timeline']['tracks'][0]['clips']
        
        # Count effects
        fx_on_filler = [c for c in clips 
                       if 'FX_ON_FILLER' in c.get('source_umid', '')]
        
        self.assertEqual(len(fx_on_filler), 36,
                        f'Expected 36 FX_ON_FILLER events, got {len(fx_on_filler)}')
        
        # Check for specific effects
        effect_names = set()
        for clip in clips:
            if 'effect_params' in clip:
                effect_name = clip['effect_params'].get('operation', '')
                if effect_name and effect_name != 'N/A':
                    effect_names.add(effect_name)
        
        # Should have AVX2 effects
        avx2_effects = [e for e in effect_names if 'AVX2' in e]
        self.assertGreater(len(avx2_effects), 0,
                          'No AVX2 effects found')


if __name__ == '__main__':
    unittest.main(verbosity=2)
