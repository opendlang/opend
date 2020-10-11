/*
	This is the source for offline web search; it will be embedded
	in a generated search page along with the search index xml.

	You will almost certainly want to gzip this when delivering it!
	Also be sure it has the proper cache headers to give a remotely
	acceptable performance result. Configure the web server to do 
	both these. When storing it for offline usage, you might just
	leave it unzipped though for convenience of use without a web server.

	Tip to the end user: you might want to open this page and keep it
	open in a reused tab.

	The file generated should be the skeleton.html with the search
	index in a <script id="search-index-container" type="text/xml">
	right before this, and this file popped in a <script> right before
	</body>.

	It concatenates them all together so it works from file://, since
	that doesn't allow XHR requests to other files so I can't just
	ajax the search.xml nor does it allow pre-gzipped assets...
*/
var searchIndexString = document.getElementById("search-index-container").innerHTML;

var parser = new DOMParser();
var searchDocument = parser.parseFromString(searchIndexString, "text/xml");


// what follows is a port of the D search cgi program. Sort of. It isn't
// actually ported since I'm not quite happy with the cgi search algorithm
// yet.

function adrdox_search(searchTerm) {
	if(searchTerm.length == 0)
		return;

	searchTerm = searchTerm.replace(/\++/g, ' ');

	if(searchTerm == window.currentSearchTerm)
		return;

	window.currentSearchTerm = searchTerm;

	location.hash = "#!" + encodeURIComponent(searchTerm);

	var hitsObj = {};

	var terms = searchTerm.split(" ");
	for(var i = 0; i < terms.length; i++) {
		var t = terms[i];
		var hitschild = searchDocument.querySelectorAll("adrdox > index > term[value=\""+stemmer(t)+"\"] > result");
		for(var a = 0; a < hitschild.length; a++) {
			if(hitsObj[hitschild[a].getAttribute("decl")])
				hitsObj[hitschild[a].getAttribute("decl")] += Number(hitschild[a].getAttribute("score"));
			else
				hitsObj[hitschild[a].getAttribute("decl")] = Number(hitschild[a].getAttribute("score"));
		}
	}

	var hits = [];
	for(name in hitsObj)
		hits.push( { decl: name, score: hitsObj[name] } );

	hits.sort(function(a, b) {
		return Number(b.score) - Number(a.score);
	});

	var container = document.getElementById("page-content");
	container.innerHTML = "<h2>Search Results</h2>";

	var resultsElement = document.createElement("dl");
	resultsElement.className = "member-list";
	container.appendChild(resultsElement);

	for(var a = 0; a < hits.length; a++) {
		var decl = searchDocument.querySelector("adrdox > listing decl[id=\""+hits[a].decl+"\"]");
		if(!decl) continue;

		var dt = document.createElement("dt");
		var link = document.createElement("a");
		link.href = decl.querySelector("link").textContent;

		var fqn = [];
		var par = decl;
		while(par) {
			fqn.push(par.querySelector("name").textContent);
			par = par.parentNode;
			if(par.tagName != "decl")
				break;
		}

		link.textContent = fqn.reverse().join(".\u200B");

		dt.appendChild(link);
		dt.className = "search-result";
		dt.setAttribute("data-score", hits[a].score);
		resultsElement.appendChild(dt);

		var dd = document.createElement("dd");
		dd.innerHTML = decl.querySelector("desc").textContent;

		resultsElement.appendChild(dd);

		if(a > 20)
			break;
	}
}

window.onhashchange = function() {
	adrdox_search(decodeURIComponent(location.hash.substring(2)));
};

window.onload = function() {
	// index the html first ...

	//foreach(element; index.querySelectorAll("adrdox > listing decl[id]"))
	//	declById[element.attrs.id] = element;
	//foreach(element; index.querySelectorAll("adrdox > index term[value]"))
	//	termByValue[element.attrs.value] = element;


	// populate the search from a form, if present
	var searchTerm = location.search.substring("?searchTerm=".length);
	if(searchTerm)
		location.href = location.href.substring(0, location.href.indexOf("?"));
	searchTerm = location.hash.substring(2);
	adrdox_search(decodeURIComponent(searchTerm));

	var search = document.getElementById("search");
	if(!search)
		return;
	search.onsubmit = function() {
		adrdox_search(search.elements["searchTerm"].value);
		return false;
	};
};

// Following is a copy/paste of a stemmer algorithm...it is BSD licensed.
// **************

// Reference Javascript Porter Stemmer. This code corresponds to the original
// 1980 paper available here: http://tartarus.org/martin/PorterStemmer/def.txt
// The latest version of this code is available at https://github.com/kristopolous/Porter-Stemmer
//
// Original comment:
// Porter stemmer in Javascript. Few comments, but it's easy to follow against the rules in the original
// paper, in
//
//  Porter, 1980, An algorithm for suffix stripping, Program, Vol. 14,
//  no. 3, pp 130-137,
//
// see also http://www.tartarus.org/~martin/PorterStemmer

var stemmer = (function(){
  var step2list = {
      "ational" : "ate",
      "tional" : "tion",
      "enci" : "ence",
      "anci" : "ance",
      "izer" : "ize",
      "bli" : "ble",
      "alli" : "al",
      "entli" : "ent",
      "eli" : "e",
      "ousli" : "ous",
      "ization" : "ize",
      "ation" : "ate",
      "ator" : "ate",
      "alism" : "al",
      "iveness" : "ive",
      "fulness" : "ful",
      "ousness" : "ous",
      "aliti" : "al",
      "iviti" : "ive",
      "biliti" : "ble",
      "logi" : "log"
    },

    step3list = {
      "icate" : "ic",
      "ative" : "",
      "alize" : "al",
      "iciti" : "ic",
      "ical" : "ic",
      "ful" : "",
      "ness" : ""
    },

    c = "[^aeiou]",          // consonant
    v = "[aeiouy]",          // vowel
    C = c + "[^aeiouy]*",    // consonant sequence
    V = v + "[aeiou]*",      // vowel sequence

    mgr0 = "^(" + C + ")?" + V + C,               // [C]VC... is m>0
    meq1 = "^(" + C + ")?" + V + C + "(" + V + ")?$",  // [C]VC[V] is m=1
    mgr1 = "^(" + C + ")?" + V + C + V + C,       // [C]VCVC... is m>1
    s_v = "^(" + C + ")?" + v;                   // vowel in stem

  function dummyDebug() {}

  function realDebug() {
    console.log(Array.prototype.slice.call(arguments).join(' '));
  }

  return function (w, debug) {
    var
      stem,
      suffix,
      firstch,
      re,
      re2,
      re3,
      re4,
      debugFunction,
      origword = w;

    if (debug) {
      debugFunction = realDebug;
    } else {
      debugFunction = dummyDebug;
    }

    if (w.length < 3) { return w; }

    firstch = w.substr(0,1);
    if (firstch == "y") {
      w = firstch.toUpperCase() + w.substr(1);
    }

    // Step 1a
    re = /^(.+?)(ss|i)es$/;
    re2 = /^(.+?)([^s])s$/;

    if (re.test(w)) { 
      w = w.replace(re,"$1$2"); 
      debugFunction('1a',re, w);

    } else if (re2.test(w)) {
      w = w.replace(re2,"$1$2"); 
      debugFunction('1a',re2, w);
    }

    // Step 1b
    re = /^(.+?)eed$/;
    re2 = /^(.+?)(ed|ing)$/;
    if (re.test(w)) {
      var fp = re.exec(w);
      re = new RegExp(mgr0);
      if (re.test(fp[1])) {
        re = /.$/;
        w = w.replace(re,"");
        debugFunction('1b',re, w);
      }
    } else if (re2.test(w)) {
      var fp = re2.exec(w);
      stem = fp[1];
      re2 = new RegExp(s_v);
      if (re2.test(stem)) {
        w = stem;
        debugFunction('1b', re2, w);

        re2 = /(at|bl|iz)$/;
        re3 = new RegExp("([^aeiouylsz])\\1$");
        re4 = new RegExp("^" + C + v + "[^aeiouwxy]$");

        if (re2.test(w)) { 
          w = w + "e"; 
          debugFunction('1b', re2, w);

        } else if (re3.test(w)) { 
          re = /.$/; 
          w = w.replace(re,""); 
          debugFunction('1b', re3, w);

        } else if (re4.test(w)) { 
          w = w + "e"; 
          debugFunction('1b', re4, w);
        }
      }
    }

    // Step 1c
    re = new RegExp("^(.*" + v + ".*)y$");
    if (re.test(w)) {
      var fp = re.exec(w);
      stem = fp[1];
      w = stem + "i";
      debugFunction('1c', re, w);
    }

    // Step 2
    re = /^(.+?)(ational|tional|enci|anci|izer|bli|alli|entli|eli|ousli|ization|ation|ator|alism|iveness|fulness|ousness|aliti|iviti|biliti|logi)$/;
    if (re.test(w)) {
      var fp = re.exec(w);
      stem = fp[1];
      suffix = fp[2];
      re = new RegExp(mgr0);
      if (re.test(stem)) {
        w = stem + step2list[suffix];
        debugFunction('2', re, w);
      }
    }

    // Step 3
    re = /^(.+?)(icate|ative|alize|iciti|ical|ful|ness)$/;
    if (re.test(w)) {
      var fp = re.exec(w);
      stem = fp[1];
      suffix = fp[2];
      re = new RegExp(mgr0);
      if (re.test(stem)) {
        w = stem + step3list[suffix];
        debugFunction('3', re, w);
      }
    }

    // Step 4
    re = /^(.+?)(al|ance|ence|er|ic|able|ible|ant|ement|ment|ent|ou|ism|ate|iti|ous|ive|ize)$/;
    re2 = /^(.+?)(s|t)(ion)$/;
    if (re.test(w)) {
      var fp = re.exec(w);
      stem = fp[1];
      re = new RegExp(mgr1);
      if (re.test(stem)) {
        w = stem;
        debugFunction('4', re, w);
      }
    } else if (re2.test(w)) {
      var fp = re2.exec(w);
      stem = fp[1] + fp[2];
      re2 = new RegExp(mgr1);
      if (re2.test(stem)) {
        w = stem;
        debugFunction('4', re2, w);
      }
    }

    // Step 5
    re = /^(.+?)e$/;
    if (re.test(w)) {
      var fp = re.exec(w);
      stem = fp[1];
      re = new RegExp(mgr1);
      re2 = new RegExp(meq1);
      re3 = new RegExp("^" + C + v + "[^aeiouwxy]$");
      if (re.test(stem) || (re2.test(stem) && !(re3.test(stem)))) {
        w = stem;
        debugFunction('5', re, re2, re3, w);
      }
    }

    re = /ll$/;
    re2 = new RegExp(mgr1);
    if (re.test(w) && re2.test(w)) {
      re = /.$/;
      w = w.replace(re,"");
      debugFunction('5', re, re2, w);
    }

    // and turn initial Y back to y
    if (firstch == "y") {
      w = firstch.toLowerCase() + w.substr(1);
    }


    return w;
  }
})();
