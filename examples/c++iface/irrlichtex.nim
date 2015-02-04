# Horrible example of how to interface with a C++ engine ... ;-)

{.link: "/usr/lib/libIrrlicht.so".}

{.emit: """
using namespace irr;
using namespace core;
using namespace scene;
using namespace video;
using namespace io;
using namespace gui;
""".}

const
  irr = "<irrlicht/irrlicht.h>"

type
  TDimension2d {.final, header: irr, importc: "dimension2d".} = object
  Tvector3df {.final, header: irr, importc: "vector3df".} = object
  TColor {.final, header: irr, importc: "SColor".} = object

  TIrrlichtDevice {.final, header: irr, importc: "IrrlichtDevice".} = object
  TIVideoDriver {.final, header: irr, importc: "IVideoDriver".} = object
  TISceneManager {.final, header: irr, importc: "ISceneManager".} = object
  TIGUIEnvironment {.final, header: irr, importc: "IGUIEnvironment".} = object
  TIAnimatedMesh {.final, header: irr, importc: "IAnimatedMesh".} = object
  TIAnimatedMeshSceneNode {.final, header: irr,
    importc: "IAnimatedMeshSceneNode".} = object
  TITexture {.final, header: irr, importc: "ITexture".} = object

  PIrrlichtDevice = ptr TIrrlichtDevice
  PIVideoDriver = ptr TIVideoDriver
  PISceneManager = ptr TISceneManager
  PIGUIEnvironment = ptr TIGUIEnvironment
  PIAnimatedMesh = ptr TIAnimatedMesh
  PIAnimatedMeshSceneNode = ptr TIAnimatedMeshSceneNode
  PITexture = ptr TITexture

proc dimension2d(x, y: cint): TDimension2d {.
  header: irr, importc: "dimension2d<u32>".}
proc vector3df(x,y,z: cint): Tvector3df {.
  header: irr, importc: "vector3df".}
proc SColor(r,g,b,a: cint): TColor {.
  header: irr, importc: "SColor".}

proc createDevice(): PIrrlichtDevice {.
  header: irr, importc: "createDevice".}
proc run(device: PIrrlichtDevice): bool {.
  header: irr, importcpp: "run".}

proc getVideoDriver(dev: PIrrlichtDevice): PIVideoDriver {.
  header: irr, importcpp: "getVideoDriver".}
proc getSceneManager(dev: PIrrlichtDevice): PISceneManager {.
  header: irr, importcpp: "getSceneManager".}
proc getGUIEnvironment(dev: PIrrlichtDevice): PIGUIEnvironment {.
  header: irr, importcpp: "getGUIEnvironment".}

proc getMesh(smgr: PISceneManager, path: cstring): PIAnimatedMesh {.
  header: irr, importcpp: "getMesh".}

proc drawAll(smgr: PISceneManager) {.
  header: irr, importcpp: "drawAll".}
proc drawAll(guienv: PIGUIEnvironment) {.
  header: irr, importcpp: "drawAll".}

proc drop(dev: PIrrlichtDevice) {.
  header: irr, importcpp: "drop".}

proc getTexture(driver: PIVideoDriver, path: cstring): PITexture {.
  header: irr, importcpp: "getTexture".}
proc endScene(driver: PIVideoDriver) {.
  header: irr, importcpp: "endScene".}
proc beginScene(driver: PIVideoDriver, a, b: bool, c: TColor) {.
  header: irr, importcpp: "beginScene".}

proc addAnimatedMeshSceneNode(
  smgr: PISceneManager, mesh: PIAnimatedMesh): PIAnimatedMeshSceneNode {.
  header: irr, importcpp: "addAnimatedMeshSceneNode".}

proc setMaterialTexture(n: PIAnimatedMeshSceneNode, x: cint, t: PITexture) {.
  header: irr, importcpp: "setMaterialTexture".}
proc addCameraSceneNode(smgr: PISceneManager, x: cint, a, b: TVector3df) {.
  header: irr, importcpp: "addCameraSceneNode".}


var device = createDevice()
if device == nil: quit "device is nil"

var driver = device.getVideoDriver()
var smgr = device.getSceneManager()
var guienv = device.getGUIEnvironment()

var mesh = smgr.getMesh("/home/andreas/download/irrlicht-1.7.2/media/sydney.md2")
if mesh == nil:
  device.drop()
  quit "no mesh!"

var node = smgr.addAnimatedMeshSceneNode(mesh)

if node != nil:
  #node->setMaterialFlag(EMF_LIGHTING, false)
  #node->setMD2Animation(scene::EMAT_STAND)
  node.setMaterialTexture(0,
    driver.getTexture(
      "/home/andreas/download/irrlicht-1.7.2/media/media/sydney.bmp"))

smgr.addCameraSceneNode(0, vector3df(0,30,-40), vector3df(0,5,0))
while device.run():
  driver.beginScene(true, true, SColor(255,100,101,140))
  smgr.drawAll()
  guienv.drawAll()
  driver.endScene()
device.drop()

