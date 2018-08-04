import canvas, dom

proc onLoad() {.exportc.} =
  var canvas = document.getElementById("canvas").EmbedElement
  canvas.width = window.innerWidth
  canvas.height = window.innerHeight
  var ctx = canvas.getContext("2d")

  ctx.fillStyle = "#1d4099"
  ctx.fillRect(0, 0, window.innerWidth, window.innerHeight)

  ctx.strokeStyle = "#ffffff"
  let letterWidth = 100
  let letterLeftPos = (window.innerWidth div 2) - (letterWidth div 2)
  ctx.moveTo(letterLeftPos, 320)
  ctx.lineTo(letterLeftPos, 110)
  ctx.lineTo(letterLeftPos + letterWidth, 320)
  ctx.lineTo(letterLeftPos + letterWidth, 110)
  ctx.stroke()
