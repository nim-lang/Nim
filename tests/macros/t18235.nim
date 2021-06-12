discard """
errormsg: '''
undeclared identifier: 'foo'
'''
"""
import m18235

# this must error out because it was never actually exported

foo()