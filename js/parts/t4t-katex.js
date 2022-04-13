/* T4T KaTeX – Helper Functions for KaTeX Math
*/








// check & create global namespace
if (!t4t){ var t4t = {}; }


/* Add Math Highlighting
----------------------------------------------- */
const texquery = '.katex-html .mord'
const hlCol = 'red'

var symbs = []

function colorTeXOn(ev){
  for (const symb of symbs) {
    if (symb.innerHTML == ev.target.innerHTML){ symb.style.color = hlCol }
  }
}
function colorTeXOff(ev){
  for (const symb of symbs) {
    if (symb.innerHTML == ev.target.innerHTML){ symb.style.color = "" }
  }
}

function addMathColorOnHoverEvents(){
  // what to select? mord that only contains only single mord children
  for (const symb of document.querySelectorAll(texquery)){
    if (!symb.innerHTML.includes("vlist") && !symb.innerHTML.includes("mord")){
      symbs.push(symb)
    }
  }

  for (const symb of symbs) {
    // alternatives: mouseenter, mouseleave
    symb.addEventListener('mouseover', colorTeXOn)
    symb.addEventListener('mouseout', colorTeXOff)
  }
}



/* Render Math
----------------------------------------------- */
var macrosNOT = {
    "\\vec": "{\\boldsymbol #1}",
    "\\ma": "\\boldsymbol{#1}",
    "\\cx": "\\boldsymbol{#1}",
    "\\cxc": "\\boldsymbol{#1}^{*}",
    "\\mat": "\\begin{bmatrix} #1 \\end{bmatrix}",
    "\\vect": "\\begin{pmatrix} #1 \\end{pmatrix}",
    "\\SI": "{#1\\,\\mathrm{#2}}",
    "\\num": "{#1}",
  };
macros = []

function renderPandocMath(){
    console.log("Rendering Math...")
    var mathElements = document.getElementsByClassName("math");
    for (var i = 0; i < mathElements.length; i++) {
        var texText = mathElements[i].firstChild;
        if (mathElements[i].tagName == "SPAN") {
         katex.render(texText.data, mathElements[i], {
          displayMode: mathElements[i].classList.contains('display'),
          throwOnError: false,
          macros: macros,
          fleqn: false
        });
    }}
}


function renderMath(){
  mathin = document.getElementsByClassName('math inline')
  Array.prototype.forEach.call(mathin, (el) => {
    try {
      katex.render(el.innerHTML, el, { displayMode: false, macros: macros })
    } catch (err) { el.innerHTML = `ERROR: ${err}` }
  })

  mathdis = document.getElementsByClassName('math display')
  Array.prototype.forEach.call(mathdis, (el) => {
    try {
      katex.render(el.innerHTML, el, { displayMode: true, macros: macros })
    } catch (err) { el.innerHTML = `ERROR: ${err}` }
  })
}










function loadScript(url, callback) {
    var script = document.createElement("script");
    script.type = 'text/javascript';
    script.src = url;
    script.onload = callback;
    document.head.appendChild(script);
}


document.addEventListener('DOMContentLoaded', function() {

  // render math
  // renderPandocMath();
  addMathColorOnHoverEvents();


  // check for MathJS
  if(document.querySelector(mathjsQuery)){
    loadScript('https://cdnjs.com/libraries/mathjs', initMathJS);
  }
})

 

/* Use MathJS
----------------------------------------------- */
const mathjsQuery = 'pre.mathjs'




function initMathJS(){
    t4t.parser = math.parser();  // requires mathjs

    // default functions
    const fac = x => x ? x * fac (x - 1) : x + 1
    const binom = (n, k) => fac (n) / fac (k) / fac (n - k >= 0 ? n - k : NaN)
    t4t.parser.set('binom', binom)

    // add intput boxes
    addMathJsInputBox();
}


function addMathJsInputBox() {
  for(const codeblock of document.querySelectorAll(mathjsQuery)){
    t4t.parser.evaluate(codeblock.innerText);
    codeblock.innerHTML += '<div style="display: flex;"><input type="text" onkeydown="onEval(this);"></input><button style="margin: 0 0 1rem;" onclick="onEval(this);">Run</button></div>'
    codeblock.firstChild.style.height = '12em';
    codeblock.firstChild.style.overflowY = 'auto';
  }
}



function onEval(ev) {
    // If the user has pressed enter or clicked button
    if(ev.tagName == 'INPUT' && window.event.keyCode === 13 || ev.tagName == 'BUTTON'){
      el = ev.parentNode.getElementsByTagName('input')[0]
      var res;
      try {
          res=t4t.parser.evaluate(el.value)
      } catch (err) {
        res = err.toString()
      }
        ev.parentNode.parentNode.firstChild.innerHTML += `\n${el.value}\n    <span class="kw">${res}</span>`
        el.value = "";
        window.event.preventDefault(); // prevent newline
      // console.log(ev.parentNode.firstChild)
    }
}


