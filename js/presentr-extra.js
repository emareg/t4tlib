/* Presentr-Extra – Functions to enhance the presentr framework for presentation slides
*/



// Footer Code
// =====================================================

const SLIDE_QUERY="header, #TOC, section.level2"


document.addEventListener('DOMContentLoaded', function() {

  footer=document.createElement("footer")
  footer.innerHTML=`<p style="margin: 1em 0;">
<span id="footinfo"></span>
<span style="float: right;">
 <span onclick="presentr.firstSlide()" class="fas fa-fast-backward"></span><span onclick="document.documentElement.requestFullscreen()" class="fas fa-expand"></span><span onclick="presentr.previousSlide()" class="fas fa-chevron-left"></span><span onclick="presentr.nextSlide()" class="fas fa-chevron-right"></span><span onclick="toggleOverlay()" class="fas fa-pencil-alt"></span><span style="display:inline-block; width: 5em; text-align: right;" id="slidenum">Slide 1</span>
</span>
</p>
<div id="progressbar"></div>
`
  footer.id='footbar'
  document.body.appendChild(footer)


  const progressbar = document.querySelector("#progressbar");
  const slidenum = document.querySelector("#slidenum");
  presentr = new Presentr({slides: SLIDE_QUERY}).on("action", () => {
    progressbar.style.width = `${(100 * (presentr.slideIndex / (presentr.totalSlides-1)))}vw`;
    slidenum.innerHTML=`Slide ${presentr.slideIndex+1}`
  });
  document.presentr = presentr  // make global

  document.body.classList.add("presentr");  // add presentr class to body

  author=document.querySelector("meta[name='author']").getAttribute('content')
  document.getElementById("footinfo").innerHTML = author +`: <span style="color: #3070b3">${document.title}</span>`;
})



// Canvas Overlay Code
// =====================================================

var canvas;
var ctx;
var draw=false;


function oMousePos(element, evt) {
  var ClientRect = element.getBoundingClientRect();
  return { x: Math.round(evt.clientX - ClientRect.left), y: Math.round(evt.clientY - ClientRect.top) }
}

function initOverlay(){
    canvas.width  = window.innerWidth;
    canvas.height = window.innerHeight;
    // canvas.style.display = "block";
    ctx.strokeStyle = "#f00";
    ctx.lineWidth = "3";
}


function toggleOverlay() {
  if (canvas.style.display==""){
    initOverlay()
    canvas.style.display = "block"
  } else {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    canvas.style.display = ""; 
  }
}

document.addEventListener('DOMContentLoaded', function() {
canvas = document.createElement("canvas")
canvas.id = "overlay"
canvas.width  = window.innerWidth;
canvas.height = window.innerHeight; 
document.body.appendChild(canvas)
ctx = canvas.getContext("2d");
ctx.strokeStyle = "#f00";

// canvas.onmousedown=function(e) {
canvas.addEventListener('mousedown', function(e) {
  oldX = (e.pageX - this.offsetLeft);
  oldY = (e.pageY - this.offsetTop);
  let m = oMousePos(this, e)
  ctx.beginPath();
  ctx.moveTo(m.x,m.y)
  draw=true;
})
canvas.addEventListener('mousemove',function(e) {
  var mouseX = (e.pageX - this.offsetLeft); //was out of scale, this gets it almost 
  var mouseY = (e.pageY - this.offsetTop); // where I want it to be, to fix
  if(draw) {
        let m = oMousePos(this, e);
        ctx.lineTo(m.x, m.y);
        ctx.stroke();
  }
})
canvas.addEventListener('mouseup',function(e) { draw=false; })

}, false);



// Spotlight Code
// =====================================================

var spotlight;
function moveSpot(e){
  spotlight.style.backgroundImage = "radial-gradient(circle at " + e.clientX + "px " + e.clientY + "px, transparent 17vh, rgba(0, 0, 0, .5) 20vh)";
}

document.addEventListener('DOMContentLoaded', function() {
  spotlight = document.createElement("div");
  spotlight.id = "spotlight"
  spotlight.className = "spotlight"
  document.body.appendChild(spotlight)

  document.body.addEventListener("contextmenu", e => e.preventDefault()); // disable menu

  for (const slide of document.querySelectorAll(SLIDE_QUERY)) {
    slide.addEventListener("contextmenu", e => e.preventDefault()); // disable menu
    slide.addEventListener("mousedown", function(e){
        if(e.which == 3){
          spotlight.style.display = "block";
          moveSpot(e);
          window.onmousemove = function(e) { moveSpot(e); }
        }
    });
  }
})


window.addEventListener("mouseup", function(e){ 
  window.onmousemove = null
  spotlight.style.display = "none"
});



// Hide Cursor when Idle
// =====================================================


function showCursorOnMove(){
  var cursorTimer = null, isCursorVisible = true;

  function hideCursor() {
      cursorTimer = null;
      document.body.style.cursor = "none";
      isCursorVisible = false;
  }

  window.addEventListener('mousemove', function(e) {
    if (cursorTimer) { window.clearTimeout(cursorTimer); }
    if (!isCursorVisible) {
        document.body.style.cursor = "inherit";
        isCursorVisible = true;
    }
    cursorTimer = window.setTimeout(hideCursor, 1000);
  });
}

showCursorOnMove()


