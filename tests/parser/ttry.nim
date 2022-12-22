# bug #21144
block:
  try:
    let c = try:
        10
      except ValueError as exc:
        10
  except ValueError as exc:
    discard

if true:
  block:
    let c = try:
          10
        except ValueError as exc:
          10
    except OSError:
      99


try:
  let c = try:
    10
  except ValueError as exc:
    10
except ValueError as exc:
  discard