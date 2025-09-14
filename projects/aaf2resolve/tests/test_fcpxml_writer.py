#!/usr/bin/env python3
'''
Test suite for write_fcpxml.py

Tests FCPXML generation from canonical JSON.
'''

import json
import sys
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'src'))

from write_fcpxml import write_fcpxml_from_canonical


class TestFCPXMLWriter(unittest.TestCase):
    '''Test the FCPXML writer'''
    
    def setUp(self):
        '''Set up test fixtures'''
        self.expected_dir = Path(__file__).parent / 'expected'
        self.temp_dir = Path(__file__).parent / 'temp'
        self.temp_dir.mkdir(exist_ok=True)
    
    def test_basic_fcpxml_generation(self):
        '''Test basic FCPXML structure generation'''
        # Create minimal canonical JSON
        canonical = {
            'timeline': {
                'name': 'Test Timeline',
                'rate': 25,
                'start': '10:00:00:00',
                'tracks': [
                    {
                        'clips': [
                            {
                                'name': 'Test Clip',
                                'in': 0,
                                'out': 100,
                                'source_umid': 'test_umid',
                                'source_path': '/path/to/media.mov',
                                'effect_params': {
                                    'operation': 'N/A',
                                    'parameters': {}
                                }
                            }
                        ]
                    }
                ]
            }
        }
        
        # Write FCPXML
        output_path = self.temp_dir / 'test_output.fcpxml'
        write_fcpxml_from_canonical(canonical, str(output_path))
        
        # Validate it's valid XML
        self.assertTrue(output_path.exists())
        
        # Parse and check structure
        tree = ET.parse(output_path)
        root = tree.getroot()
        
        self.assertEqual(root.tag, 'fcpxml')
        self.assertEqual(root.get('version'), '1.11')
    
    def tearDown(self):
        '''Clean up temp files'''
        import shutil
        if self.temp_dir.exists():
            shutil.rmtree(self.temp_dir)


if __name__ == '__main__':
    unittest.main(verbosity=2)
