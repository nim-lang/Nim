discard """
  output: '''
123
123
'''
  ccodecheck: "'extern NI /* custom declaration */ codegenDeclGlobal'"
  targets: "c cpp"
"""

import ./mcodegendeclglobal

echo codegenDeclGlobal
echo readCodegenDeclGlobal()
