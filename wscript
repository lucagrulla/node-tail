import Options
from os import unlink, link
from os.path import exists 

APPNAME = 'tail'
VERSION = "0.1.0"

def set_options(opt):
    opt.tool_options("compiler_cxx")

def configure(conf):
  
def build(bld):
    bld(rule='./node_modules/coffee -c ${TGT}', target='tail.coffee')
    
def shutdown():
  # HACK to get binding.node out of build directory.
  # better way to do this?
  if exists('./binding.node'): unlink('./binding.node')
  if Options.commands['build']:
    link('./build/default/binding.node', './binding.node')
