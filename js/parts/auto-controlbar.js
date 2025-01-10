/* Auto Controlbar – Add a navbar automatically.
*/

// get the first num words of a sentence string
function getWords(str, num) {
    return str.split(/\s+/).slice(0,num).join(" ");
}


function addBreadCrumbs(el){
  const here = location.href.split('/').slice(3);
  const parts = [{"text": 'Home', "link": '/'}];

  for (let i = 0; i < here.length-1; i++) {
    const text = decodeURIComponent(here[i]).split('.')[0];
    const link = '/' + here.slice(0, i + 1).join('/');
    parts.push({"text": text, "link": link});
  }
  el.innerHTML = parts.map((part) => {
    return "<a href=\"" + part.link + "\">" + part.text + "</a>"
  }).join('<span style="padding: 5px">/</span>')
}

// scroll
/* When the user scrolls down, hide the navbar. When the user scrolls up, show the navbar */
// window.onscroll = function() {
var prevScrollpos = window.pageYOffset;
window.addEventListener('scroll', function() {
  var currentScrollPos = window.pageYOffset;
  if (prevScrollpos > currentScrollPos) {
    document.getElementById("ctrlbar").style.top = "0";
  } else {
    document.getElementById("ctrlbar").style.top = "-50px";
  }
  prevScrollpos = currentScrollPos;
})


function addFontSize(addPx){
  html = document.querySelector('html');
  currentSize = parseFloat(window.getComputedStyle(html, null)
    .getPropertyValue('font-size'));
  html.style.fontSize = (currentSize + addPx) + 'px';
}

function toggleDarkMode(el){
  var theme='light'
  if (el.innerText == '☪'){
    el.innerText = '☀'; theme='dark';
  } else {
    el.innerText = '☪';
  }
  document.documentElement.setAttribute('data-theme', theme)
}


// register on load
document.addEventListener('DOMContentLoaded', function() {

  ctrlBar = document.createElement('nav');
  ctrlBar.id = 'ctrlbar'
  ctrlBar.style = "position: fixed; width: 100%; top: 0; background-color: var(--cbg);";
  ctrlBar.innerHTML = '<div class="qdoc-buttons noprint"><span id="qbread"></span><a onclick="toggleDarkMode(this)">☪</a>&nbsp;<a onclick="addFontSize(-1)">ᴀ-</a>&nbsp;|&nbsp;<a onclick="addFontSize(1)">A+</a></div>'
  document.body.prepend(ctrlBar);
  addBreadCrumbs(document.getElementById("qbread"))

})
