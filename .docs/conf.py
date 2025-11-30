# Configuration file for Sphinx documentation builder
# See https://www.sphinx-doc.org/en/master/usage/configuration.html

import os
import sys

project = 'RPEngine'
copyright = '2024, FrontierDev'
author = 'FrontierDev'
release = '1.0'

# Add project root to path
sys.path.insert(0, os.path.abspath('..'))

extensions = [
    'sphinx.ext.autodoc',
    'sphinx.ext.intersphinx',
    'sphinx.ext.todo',
    'sphinx_rtd_theme',
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

# ReadTheDocs theme
html_theme = 'sphinx_rtd_theme'
html_theme_options = {
    'logo_only': False,
    'display_version': True,
    'prev_next_buttons_location': 'bottom',
    'style_external_links': False,
    'vcs_pageview_mode': 'edit',
    'style_nav_header_background': '#2980B9',
}

html_static_path = ['_static']
html_logo = None

# Intersphinx mapping
intersphinx_mapping = {
    'python': ('https://docs.python.org/3', None),
}
