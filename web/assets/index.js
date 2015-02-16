"use strict";

var timer;
var prevIndex = 0;
var slideCount = 2;

function setSlideShow(index, short) {
  if (index >= slideCount) index = 0;
  document.getElementById("slide"+prevIndex).className = "";
  document.getElementById("slide"+index).className = "active";
  document.getElementById("slideControl"+prevIndex).className = "";
  document.getElementById("slideControl"+index).className = "active";
  prevIndex = index;
  startTimer(short ? 8000 : 32000);
}

function nextSlide() { setSlideShow(prevIndex + 1, true); }
function startTimer(t) { timer = setTimeout(nextSlide, t); }

function slideshow_enter() { clearTimeout(timer); }
function slideshow_exit () { startTimer(16000); }

function slideshow_click(index) {
  clearTimeout(timer);
  setSlideShow(index, false);
}

window.onload = function() {
  var slideshow = document.getElementById("slideshow");
  slideshow.onmouseenter = slideshow_enter;
  slideshow.onmouseleave = slideshow_exit;
  slideCount = slideshow.children.length;
  startTimer(8000);
};