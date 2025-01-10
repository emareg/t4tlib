listStyle=`
/* (A) CONTAINER */
.collapse, .collapse ul {
  list-style-type: none;
  padding-left: 10px;
}

/* (B) LIST ITEMS */
.collapse li { padding: 10px; }

/* (C) TOGGLE */
.toggle {
  padding: 10px;
  cursor: pointer;
}
.toggle::before {
  display: inline-block;
  width: 15px;
  content: "+";
}
.toggle.show::before { content: "-"; }

/* (D) SHOW/HIDE */
.collapse ul { display: none; }
.toggle.show + ul { display: block; }
`

window.addEventListener("load", () => {
    for (let i of document.querySelectorAll(".collapse ul")) {
      let tog = document.createElement("div");
      tog.innerHTML = i.previousSibling.textContent;
      tog.className = "toggle";
      tog.onclick = () => tog.classList.toggle("show");
      i.parentElement.removeChild(i.previousSibling);
      i.parentElement.insertBefore(tog, i);
    }
  });