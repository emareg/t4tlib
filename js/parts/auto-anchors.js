/* Auto Anchors – Add anchors to headings and paragraphs
*/

// get the first num words of a sentence string
function getWords(str, num) {
    return str.split(/\s+/).slice(0,num).join(" ");
}

function clipBoard(value) {
  var tempInput = document.createElement("input");
  tempInput.style = "position: absolute; left: -1000px; top: -1000px";
  tempInput.value = value;
  document.body.appendChild(tempInput);
  tempInput.select();
  document.execCommand("copy");
  document.body.removeChild(tempInput);
}

// add IDs to certain elements
function addIDs(query, prefix=""){
    document.querySelectorAll(query).forEach($el => {

      //create id from text
      var short = $el.innerText.toLowerCase();
      if (short.length > 25){ short = getWords(short, 5); }
      var id = $el.getAttribute("id") || prefix+short.replace(/[`~!@#$%^&*()_|+\-=?;:'",.<>\{\}\[\]\\\/]/gi, '').replace(/ +/g, '-');

      //add id to heading
      $el.setAttribute('id', id);
    })
}

function addAnchor(prevH, thisH, nextH){
  $anchor = document.createElement('div');
  $anchor.className = 'anchor-link';

  thisAnchor = document.createElement('a');
  thisAnchor.href = '#' + thisH.getAttribute("id");
  thisAnchor.innerText = '#';
  thisAnchor.addEventListener('click', function (el) { 
    clipBoard(el.target.href)}
  )
  $anchor.appendChild(thisAnchor);

  if (prevH){
      prevAnchor = document.createElement('a');
      prevAnchor.href = '#' + prevH.getAttribute("id");
      prevAnchor.innerText = '▲';
      $anchor.appendChild(prevAnchor);
  }

  if (nextH){
      nextAnchor = document.createElement('a');
      nextAnchor.href = '#' + nextH.getAttribute("id");
      nextAnchor.innerText = '▼';
      $anchor.appendChild(nextAnchor);
  }
  thisH.prepend($anchor)
}


// register on load
document.addEventListener('DOMContentLoaded', function() {

    addIDs('article h1, article h2, article h3', 'h-');
    headings = document.querySelectorAll('article h2');

    for (var i = 0; i < headings.length; i++) {
        prevH = nextH = null
        if (i != 0){ prevH = headings[i-1]}
        if (i != headings.length){ nextH = headings[i+1]}
        addAnchor(headings[i-1], headings[i], headings[i+1])
    }

    // p_query = 'article h2 ~ p, article h3 ~ p';
    p_query = 'article section > p, article h2 ~ p, article figure > figcaption';
    addIDs(p_query, 'p-');
    ps = document.querySelectorAll(p_query);
    for (const p of ps){
      $anchor = document.createElement('a');
      $anchor.href = '#' + p.getAttribute('id');
      $anchor.className = 'anchor-link';
      $anchor.style = 'position: absolute; display: none; margin: 0 -.5em 0 .5em;';
      $anchor.innerText = ' ¶';
      p.appendChild($anchor);      
    }
});