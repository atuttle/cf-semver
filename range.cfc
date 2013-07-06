/*
	This CFC is mostly a port (with CF-specific updates) of the Node.js semver package, by Isaac Schlueter @izs

	I can't take credit for anything genius within, but I do claim ownership of port-specific bugs!

	The original module was available under the BSD license, therefore this port will also use the BSD license.
	http://opensource.org/licenses/BSD-3-Clause
*/
component extends="semverrules" {

	/******************************************************************************************************************
	 *	Use this odd (to CF) function declaration syntax so we can overload 1st class function names like EQ and GTE
	 *    this.x = function( ... ){ ... }
	 *****************************************************************************************************************/

	//ported from function Range()
	this.init = function(range, loose = false){
		if (isInstanceOf(range, "range") && range.loose == arguments.loose){
			return range;
		}

// todo: support instantiation with no args
// 		if (arrayLen(arguments) == 0){
// 			this.loose = false;
// 			this.raw = '*';
// 			this.set = [ parseRange('*') ];
// 		}

		this.loose = arguments.loose;

		//empty string = *
		if (arguments.range == '') arguments.range = '>=*';

		// First, split based on boolean or ||
		this.raw = range;
		range = replace(range, '||', chr(11), 'ALL');
		this.set = listToArray(range, chr(11), true);
		for (var i = 1; i <= arrayLen(this.set); i++){
			if (!len(this.set[i])) this.set[i] = '*';
			this.set[i] = parseRange(trim(this.set[i]));
		}

		if (!arrayLen(this.set)) {
			throw 'Invalid SemVer Range: `#range#`';
		}

		this.format();

		return this;
	};

	this.inspect = function() {
		return '<SemVer Range "' & this.range & '">';
	};

	this.format = function() {
		var retSet = [];
		arrayEach(this.set, function(comps){
			var tmp = [];
			arrayEach(comps, function(c){
				arrayAppend(tmp, c.value);
			});
			arrayAppend(retSet, arrayToList(tmp, ' '));
		});
		this.range = trim(arrayToList(retSet, '||'));
		return this.range;
	};

	this.toString = function() {
		return this.range;
	};

	function parseRange(range) {
		var loose = this.loose;
		range = trim(range);

// writeDump(arguments);
		// `1.2.3 - 1.2.4` => `>=1.2.3 <=1.2.4`
		var hr = loose ? this.src[HYPHENRANGELOOSE] : this.src[HYPHENRANGE];
		range = slipstream(range, hr, "hyphenReplace");
// writeDump(range);
		// `> 1.2.3 < 1.2.5` => `>1.2.3 <1.2.5`
		range = reReplace(range, "\s+", " ", "ALL");
		range = replaceList(range, "> ,< ,>= ,<= ,~ ", ">,<,>=,<=,~");
// writeDump(range);

		// At this point, the range is completely trimmed and
		// ready to be split into comparators.
		var set = listToArray(range, ' ');

// writeDump(set);
		var compRe = loose ? this.src[COMPARATORLOOSE] : this.src[COMPARATOR];
		for (var i = 1; i <= arrayLen(set); i++){
			set[i] = parseComparator(set[i], loose);
		}
		//sometimes parse puts 2 comparators into 1 array item, so re-split them
		if (arrayLen(set) == 1 && find(" ", set[1]) > 0){
			set = listToArray(set[1], ' ');
		}
// writeDump(set);
		for (var i = arrayLen(set); i > 0; i--){
			if (!len(trim(set[i]))){
				arrayDeleteAt(set, i);
			}
		}
		if (this.loose) {
			// in loose mode, throw out any that are not valid comparators
			arrayFilter(set, function(comp){
				return arrayLen(reMatch(compRe, comp)) > 0;
			});
		}
writeDump(var={set=set},label='set');
		for (var i = 1; i <= arrayLen(set); i++){
			if (set[i] == '') set[i] = '*';
			if (set[i] == '*' || lcase(set[i]) == 'x') set[i] = '>=0.0.0';
			set[i] = new comparator(set[i], loose);
		}

		return set;
	};

	//intentionally omitting "toComparators" method; suspect we won't need it (was included for legacy reasons in Node)

	private function isX(id){
		return (len(id) == 0 || id == '*' || lcase(id) == 'x');
	}

	private function parseComparator(comp, loose = false){
// writeDump(var=arguments,label='parseComparator args');
		arguments.comp = replaceTildes(arguments.comp, arguments.loose);
// writeDump(var=arguments,label='after tildes');
		arguments.comp = replaceXRanges(arguments.comp, arguments.loose);
// writeDump(var=arguments,label='after xRanges');
		arguments.comp = replaceStars(arguments.comp, arguments.loose);
// writeDump(var=arguments,label='after stars');
		return arguments.comp;
	}

	// ~, ~> --> * (any, kinda silly)
	// ~2, ~2.x, ~2.x.x, ~>2, ~>2.x ~>2.x.x --> >=2.0.0 <3.0.0
	// ~2.0, ~2.0.x, ~>2.0, ~>2.0.x --> >=2.0.0 <2.1.0
	// ~1.2, ~1.2.x, ~>1.2, ~>1.2.x --> >=1.2.0 <1.3.0
	// ~1.2.3, ~>1.2.3 --> >=1.2.3 <1.3.0
	// ~1.2.0, ~>1.2.0 --> >=1.2.0 <1.3.0
	private function replaceTildes(comp, loose = false) {
		if (find("~", comp) == 0) return comp;
		var result = listToArray(trim(comp), ' ');
		for (var i = 1; i <= arrayLen(result); i++){
			result[i] = replaceTilde(result[i]);
		}
		return arrayToList(result, ' ');
	}

	private function replaceTilde(comp, loose = false) {
		var r = (loose ? this.src[TILDELOOSE] : this.src[TILDE]);
		return slipstream(comp, r, "tildeCleaner");
	}
	private function tildeCleaner(ret = '', Major = '', minor = '', patch = '', pre = '', preNoHyphen = '') {
// writeDump(var=arguments,label='tildeCleaner args');
		if (isX(Major))      {ret = '';}
		else if (isX(minor)) {ret = '>=' & Major & '.0.0-0 <' & (val(Major) + 1) & '.0.0-0';}
		else if (isX(patch)) {ret = '>=' & Major & '.' & minor & '.0-0 <' & Major & '.' & (val(minor) + 1) & '.0-0';} // ~1.2 == >=1.2.0- <1.3.0-
		else if (pre != '') {
			if (left(pre, 1) != '-'){
				pre = '-' & pre;
			}
			// ~1.2.3 == >=1.2.3-0 <1.3.0-0
			ret = '>=' & Major & '.' & minor & '.' & patch & pre & ' <' & Major & '.' & (val(minor) + 1) & '.0-0';
		}else{
			ret = '>=' & Major & '.' & minor & '.' & patch & '-0' & ' <' & Major & '.' & (val(minor) + 1) & '.0-0';
		}
// writeDump(var=local,label='tildeCleaner end');
		return ret;
	}

	private function replaceXRanges(comp, loose = false) {
		var result = listToArray(trim(comp), ' ');
		for (var i = 1; i <= arrayLen(result); i++){
			result[i] = replaceXRange(result[i]);
		}
		return arrayToList(result, ' ');
	}

	private function replaceXRange(comp, loose = false) {
		arguments.comp = trim(arguments.comp);
		var r = loose ? this.src[XRANGELOOSE] : this.src[XRANGE];
		return slipstream(comp, r, "xRangeCleaner");
	}
	private function xRangeCleaner(ret = '', gtlt = '', Major = '', minor = '', patch = '', pre = '') {
		var chunks = listToArray(replaceList(ret, '<,>,=,~', ',,,'), '.'); // <2 => 2
		var numChunks = arrayLen(chunks);
		if (numChunks == 1) {
			Major = (isNumeric(chunks[1]) ? val(chunks[1]) : 'x');
			minor = 'x';
		}
		if (numChunks == 2) {
			Major = (isNumeric(chunks[1]) ? val(chunks[1]) : 'x');
			minor = (isNumeric(chunks[2]) ? val(chunks[2]) : 'x');
			patch = 'x';
		}
// writeDump(var=local,label='xRangeCleaner args');

		var xMajor = isX(Major);
		var xMinor = xMajor || isX(minor);
		var xPatch = xMinor || isX(patch);
		var anyX = xPatch;

		if (gtlt == '=' && anyX) gtlt = '';

		if (len(gtlt) && anyX) {
			// replace X with 0, and then append the -0 min-prerelease
			if (xMajor) Major = 0;
			if (xMinor) minor = 0;
			if (xPatch) patch = 0;

			if (gtlt == '>') {
				// >1 => >=2.0.0-0
				// >1.2 => >=1.3.0-0
				// >1.2.3 => >= 1.2.4-0
				gtlt = '>=';
				if (xMajor) {
					// no change
				} else if (xMinor) {
					Major = val(Major) + 1;
					minor = 0;
					patch = 0;
				} else if (xPatch) {
					minor = val(minor) + 1;
					patch = 0;
				}
			}

			ret = gtlt & Major & '.' & minor & '.' & patch & '-0';
		} else if (xMajor) {
			// allow any
			ret = '*';
		} else if (xMinor) {
			// append '-0' onto the version, otherwise
			// '1.x.x' matches '2.0.0-beta', since the tag
			// *lowers* the version value
			ret = '>=' & Major & '.0.0-0 <' & (val(Major) + 1) & '.0.0-0';
		} else if (xPatch) {
			ret = '>=' & Major & '.' & minor & '.0-0 <' & Major & '.' & (val(minor) + 1) & '.0-0';
		}

		return ret;
	}

	// Because * is AND-ed with everything else in the comparator,
	// and '' means "any version", just remove the *s entirely.
	private function replaceStars(comp, loose = false) {
		// Looseness is ignored here.  star is always as loose as it gets!
		return reReplace(trim(comp), this.src[STAR], '', 'ALL');
	}

	// This function is passed to string.replace(re[HYPHENRANGE])
	// M, m, patch, prerelease, build
	// 1.2 - 3.4.5 => >=1.2.0-0 <=3.4.5
	// 1.2.3 - 3.4 => >=1.2.0-0 <3.5.0-0 Any 3.4.x will do
	// 1.2 - 3.4 => >=1.2.0-0 <3.5.0-0
	private function hyphenReplace(junk = '', from = '', fMaj = '', fMin = '', fp = '', fpr = '', fb = '', to = '', tMaj = '', tMin = '', tp = '', tpr = '', tb = '') {
		//"junk" argument is a symptom of differing regex approaches in original nodejs module;
		// sometimes the whole pattern is captured, sometimes not (this one is a yes).
		// we've opted to always prepend the original string as the first argument (see implementation of slipstream function)
		// so sometimes (like now) we need to ignore it.
// writeDump(var=arguments,label='hyphenReplace args');
		if (find(" - ", junk) == 0) return junk;

		if (isX(fMaj))                from = '';
		else if (isX(fMin))           from = '>=' & fMaj & '.0.0-0';
		else if (isX(fp) || !len(fp)) from = '>=' & fMaj & '.' & fMin & '.0-0';
		else                          from = '>=' & from;

		if (isX(tMaj))                to = '';
		else if (isX(tMin))           to = '<' & (+tMaj & 1) & '.0.0-0';
		else if (isX(tp) || !len(tp)) to = '<' & tMaj & '.' & (tMin & 1) & '.0-0';
		else if (len(tpr))            to = '<=' & tMaj & '.' & tMin & '.' & tp & '-' & tpr;
		else                          to = '<=' & to;

		return trim(from & ' ' & to);
	}

	// if ANY of the sets match ALL of its comparators, then pass
	function test(version) {
		for (var i = 1; i <= arrayLen(this.set); i++) {
			if (testSet(this.set[i], version)) return true;
		}
		return false;
	};

	private function testSet(comparators, version){
		for (var i = 1; i <= arrayLen(arguments.comparators); i++) {
			if (!arguments.comparators[i].test(version)) return false;
		}
		return true;
	}

	function satisfies(version, range, loose = false) {
		try {
			range = new Range(range, loose);
		} catch (any er) {
// writeDump(var=er);
			return false;
		}
		return range.test(version);
	};

	function maxSatisfying(versions, range, loose = false) {
		//versions is an array of version strings
		var matches = arrayFilter(versions, function(v){ return satisfies(v, range, loose); });
		var sortedMatches = arraySort(matches, 'text', 'desc');
		return (arrayLen(sortedMatches) > 0 ? sortedMatches[1] : '');
	};

	private function validRange(range, loose = false) {
		try {
			// Return '*' instead of '' so that truthiness works.
			// This will throw if it's invalid anyway
			return new Range(range, loose).range;
		} catch (any er) {
			return '';
		}
	}


	/*
	 * Additions: These methods are not ports
	 *********************************************/

	//this function (and reFindNoSuck) emulate the behavior of JavaScript's string.replace(pattern, fn) behavior
	private function slipstream(str, pattern, callback){
// writeDump(var=arguments,label='slipstream arguments');
		var matches = reFindNoSuck(pattern, str);
		arrayPrepend(matches, str);//include the original string as the first argument
		return invoke("", callback, matches);//call the callback and pass it the matches
	}

	private function reFindNoSuck(required string pattern, required string data, numeric startPos = -1) output="false" {
		var local = StructNew();
		local.awesome = arrayNew(1);
		local.sucky = refindNoCase(arguments.pattern, arguments.data, arguments.startPos, true);
		if (not isArray(local.sucky.len) or arrayLen(local.sucky.len) eq 0){return arrayNew(1);} //handle no match at all
		for (local.i=1; local.i<= arrayLen(local.sucky.len); local.i++){
				if (local.sucky.len[local.i] eq 0){
					local.matchBody = "";
				}else{
					local.matchBody = mid(arguments.data, local.sucky.pos[local.i], local.sucky.len[local.i]);
				}
				//don't include the group that matches the entire pattern
				if (local.matchBody neq arguments.data){
					arrayAppend( local.awesome, local.matchBody );
				}
		}
		return local.awesome;
	}

}
