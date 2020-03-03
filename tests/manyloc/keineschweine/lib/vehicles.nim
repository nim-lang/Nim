import
  sfml, chipmunk,
  sg_assets, sfml_stuff#, "../keineschweine"


proc accel*(obj: PVehicle, dt: float) =
  #obj.velocity += vec2f(
  #  cos(obj.angle) * obj.record.handling.thrust.float * dt,
  #  sin(obj.angle) * obj.record.handling.thrust.float * dt)
  obj.body.applyImpulse(
    vectorForAngle(obj.body.getAngle()) * dt * obj.record.handling.thrust,
    VectorZero)
proc reverse*(obj: PVehicle, dt: float) =
  #obj.velocity += vec2f(
  #  -cos(obj.angle) * obj.record.handling.reverse.float * dt,
  #  -sin(obj.angle) * obj.record.handling.reverse.float * dt)
  obj.body.applyImpulse(
    -vectorForAngle(obj.body.getAngle()) * dt * obj.record.handling.reverse,
    VectorZero)
proc strafe_left*(obj: PVehicle, dt: float) =
  obj.body.applyImpulse(
    vectorForAngle(obj.body.getAngle()).perp() * obj.record.handling.strafe * dt,
    VectorZero)
proc strafe_right*(obj: PVehicle, dt: float) =
  obj.body.applyImpulse(
    vectorForAngle(obj.body.getAngle()).rperp() * obj.record.handling.strafe * dt,
    VectorZero)
proc turn_right*(obj: PVehicle, dt: float) =
  #obj.angle = (obj.angle + (obj.record.handling.rotation.float / 10.0 * dt)) mod TAU
  obj.body.setTorque(obj.record.handling.rotation)
proc turn_left*(obj: PVehicle, dt: float) =
  #obj.angle = (obj.angle - (obj.record.handling.rotation.float / 10.0 * dt)) mod TAU
  obj.body.setTorque(-obj.record.handling.rotation)
proc offsetAngle*(obj: PVehicle): float {.inline.} =
  return (obj.record.anim.angle + obj.body.getAngle())
