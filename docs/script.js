window.addEventListener("load", function() {

	var lineWrappers = document.querySelectorAll(".with-line-wrappers");
	for(var i = 0; i < lineWrappers.length; i++) {
		var l = lineWrappers[i];

		var codeblock = document.createElement("div");
		codeblock.className = "codeblock";
		l.parentNode.insertBefore(codeblock, l);

		var header = document.createElement("header");
		codeblock.appendChild(header);
		codeblock.appendChild(l);

		var btn = document.createElement("button");
		btn.setAttribute("type", "button");
		var canCopyToClipboard = document.queryCommandSupported("copy");
		btn.addEventListener("click", (function(l) { return function() {
			document.body.classList.add("hide-line-numbers");
			window.getSelection().selectAllChildren(l);
			if(canCopyToClipboard)
				if(!document.execCommand("copy")) {
					alert("copy failed, try ctrl+c manually");
				}
		};})(l));
		btn.textContent = canCopyToClipboard ? "Copy to Clipboard" : "Select All";
		header.appendChild(btn);

		var btn = document.createElement("button");
		btn.setAttribute("type", "button");
		btn.addEventListener("click", function() {
			document.body.classList.toggle("hide-line-numbers");
		});
		btn.textContent = "Toggle Line Numbers";
		header.appendChild(btn);
	}

	/* // still sucks in firefox!
	document.addEventListener("copy", function(event) {
		document.body.classList.add("hide-line-numbers");
	});
	*/

	document.body.addEventListener("mouseover", function(event) {
		if(event.target.hasAttribute("data-ident")) {
			var all = document.querySelectorAll("[data-ident=\""+event.target.getAttribute("data-ident")+"\"]");
			for(var i = 0; i < all.length; i++)
				all[i].className += " active";
		}
	});
	document.body.addEventListener("mouseout", function(event) {
		if(event.target.hasAttribute("data-ident")) {
			var all = document.querySelectorAll("[data-ident=\""+event.target.getAttribute("data-ident")+"\"]");
			for(var i = 0; i < all.length; i++)
				all[i].className = all[i].className.replace(" active", "");
		}
	});
	/*
	document.body.addEventListener("dblclick", function(event) {
		if(event.target.hasAttribute("data-ident")) {
			location.href = "/" + event.target.getAttribute("data-ident");
		}
	});
	*/

	var sn = document.getElementById("source-navigation");
	if(sn) {
		sn.addEventListener("click", function(event) {
			if(event.target.tagName != "A" || event.target.className == "docs")
				return true;
			if(event.target.nextSibling) {
				var s = event.target.nextSibling;
				if(s.style.display == "" || s.style.display == "none" || s.className.indexOf("search-hit") != -1) {
					s.style.display = "block";
					var items = s.getElementsByTagName("ul");
					var i;
					for(i = 0; i < items.length; i++)
						items[i].style.display = "";
					items = s.getElementsByTagName("li");
					for(i = 0; i < items.length; i++)
						items[i].style.display = "";
				} else
					s.style.display = "";
			}

			//var id = event.target.href.substring(event.target.href.indexOf("#") + 1);
			//sn.style.marginTop = (document.getElementById(id).offsetTop - event.target.offsetTop + 16) + "px";
		});

		var search = document.createElement("input");
		search.setAttribute("type", "search");
		function searchHelper() {
			var regex = new RegExp(search.value, "i");
			var items = document.querySelectorAll("#source-navigation a[href^=\"#\"]");
			var stxt = search.value;
			for(var i = 0; i < items.length; i++) {
				var a = items[i];
				if(stxt.length && regex.test(a.textContent)) {
					var p = a.parentNode;
					while(p.tagName != "DIV") {
						if(p.tagName == "LI")
							p.style.display = "list-item";
						else
							p.style.display = "block";
						p.className += " search-hit";
						p = p.parentNode;
					}
				} else {
					var p = a.parentNode;
					if(stxt.length == 0) {
						p.style.display = "";
						while(p.tagName != "DIV") {
							p.style.display = "";
							p = p.parentNode;
						}
					} else
						p.style.display = "none";
					p.className = p.className.replace(" search-hit", "");
				}
			}
		}
		search.addEventListener("keyup", searchHelper);
		sn.insertBefore(search, sn.firstChild);
	}

	/*
	function updateDynamicStyle() {
		var thing = document.getElementById("page-content");
		var newStyle = document.getElementById("dynamic-style");
		if(!newStyle) {
			newStyle = document.createElement("style");
			newStyle.setAttribute("id", "dynamic-style");
			newStyle.type = "text/css";
			document.head.appendChild(newStyle);
		}

		var maxContentWidth = window.innerWidth;
		// 800 is the threshold for putting nav vertically
		if(maxContentWidth < 800)
			maxContentWidth = 800;
		else
			maxContentWidth =
				document.body.offsetWidth -
				document.getElementById("page-nav").offsetWidth -
				document.getElementById("page-nav").offsetLeft -
				64;

		// sanity check lol
		if(maxContentWidth < 800)
			maxContentWidth = 800;

		newStyle.innerHTML = ".member-list:not(.constructors) dt .simplified-prototype:hover { width: " + (thing.offsetWidth - 32) + "px; } #page-content pre.d_code, #page-content .overload-option, #page-content .member-list dt { max-width: " + (maxContentWidth) + "px; }";
	}

	updateDynamicStyle();

	window.onresize = updateDynamicStyle;
	*/

	// Disable line numbers in IE because the copy/paste with them sucks - it includes all line numbers
	// in the middle making it too hard to use. Copy/paste is more important than line displays.
	if (navigator.userAgent.indexOf('MSIE') !== -1 || navigator.appVersion.indexOf('Trident/') > 0) {
		var items = document.querySelectorAll(".with-line-wrappers");
		for(var a = 0; a < items.length; a++)
			items[a].className = items[a].className.replace("with-line-wrappers", "");
	}

});
