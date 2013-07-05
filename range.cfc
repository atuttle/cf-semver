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

		this.loose = arguments.loose;

		// First, split based on boolean or ||
		this.raw = range;
		range = replace(range, ' || ', chr(11), 'ALL');
		this.set = listToArray(range, chr(11));
		for (var i = 1; i <= arrayLen(this.set); i++){
			this.set[i] = this.parseRange(trim(this.set[i]));
		}
		for (var i = arrayLen(this.set); i > 0; i--){
			if (len(trim(this.set[i])) == 0){
				arrayDeleteAt(this.set, i);
			}
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
		var tmp = [];
		arrayEach(this.set, function(comps){
			arrayAppend(tmp, trim(arrayToList(comps, ' ')));
		});
		this.range = trim(arrayToList(tmp, '||'));
		return this.range;
	};

	this.toString = function() {
		return this.range;
	};

	/*
	 * PRIVATE METHODS
	 */

	remote function parseRange(range) {
		var loose = true;//this.loose;
		range = trim(range);

		// `1.2.3 - 1.2.4` => `>=1.2.3 <=1.2.4`
		var hr = loose ? this.src[.HYPHENRANGELOOSE] : this.src[.HYPHENRANGE];
		range = slipstream(range, hr, "hyphenReplace");

		// `> 1.2.3 < 1.2.5` => `>1.2.3 <1.2.5`
		range = replaceList(range, "> ,< ,>= ,<= ,~ ", ">,<,>=,<=,~");

		// normalize spaces
		range = arrayToList(listToArray(range, ' '), ' ');
		// writeDump(var=range,abort=true);

		// At this point, the range is completely trimmed and
		// ready to be split into comparators.

		var compRe = loose ? this.src[.COMPARATORLOOSE] : this.src[.COMPARATOR];
		var set = listToArray(range, ' ');
		for (var i = 1; i <= arrayLen(set); i++){
			set[i] = parseComparator(comp, loose);
		}
		for (var i = arrayLen(set); i > 0; i--){
			if (!len(trim(set[i]))){
				arrayDeleteAt(set, i);
			}
		}
		if (this.loose) {
			// in loose mode, throw out any that are not valid comparators
			set = set.filter(function(comp) {
				return !!comp.match(compRe);
			});
		}
		set = set.map(function(comp) {
			return new Comparator(comp, loose);
		});

		return set;
	};

	//intentionally omitting "toComparators" method; suspect we won't need it (was included for legacy reasons in Node)

	private function isX(id){
		return (id == '*' || lcase(id) == 'x');
	}

	private function parseComparator(comp, loose){
		arguments.comp = replaceTildes(arguments.comp, arguments.loose);
		arguments.comp = replaceXRanges(arguments.comp, arguments.loose);
		arguments.comp = replaceStars(arguments.comp, arguments.loose);
		return arguments.comp;
	}

	// ~, ~> --> * (any, kinda silly)
	// ~2, ~2.x, ~2.x.x, ~>2, ~>2.x ~>2.x.x --> >=2.0.0 <3.0.0
	// ~2.0, ~2.0.x, ~>2.0, ~>2.0.x --> >=2.0.0 <2.1.0
	// ~1.2, ~1.2.x, ~>1.2, ~>1.2.x --> >=1.2.0 <1.3.0
	// ~1.2.3, ~>1.2.3 --> >=1.2.3 <1.3.0
	// ~1.2.0, ~>1.2.0 --> >=1.2.0 <1.3.0
	private function replaceTildes(comp, loose){
		var result = listToArray(trim(comp), ' ');
		for (var i = 1; i <= arrayLen(result); i++){
			result[i] = replaceTilde(result[i]);
		}
		return arrayToList(result, ' ');
	}

	private function replaceTilde(comp, loose) {
		var r = (loose ? this.src[TILDELOOSE] : this.src[TILDE]);
		var cleaner = function(_, Major, minor, patch, pre) {
			var ret = '';
			if (isX(Major))      ret = '';
			else if (isX(minor)) ret = '>=' & Major & '.0.0-0 <' & (val(Major) + 1) & '.0.0-0';
			else if (isX(patch)) ret = '>=' & Major & '.' & minor & '.0-0 <' & Major & '.' & (val(minor) + 1) & '.0-0'; // ~1.2 == >=1.2.0- <1.3.0-
			else if (pre != '') {
				if (left(pre, 1) != '-'){
					pre = '-' & pre;
					ret = '>=' & Major & '.' & minor & '.' & patch & pre & ' <' & Major & '.' & (val(minor) + 1) & '.0-0';
				} else {
					// ~1.2.3 == >=1.2.3-0 <1.3.0-0
					ret = '>=' & Major & '.' & minor & '.' & patch & '-0' & ' <' & Major & '.' & (val(minor) + 1) & '.0-0';
				}
			}
			return ret;
		};
		return slipstream(comp, r, cleaner);
	}

	private function replaceXRanges(comp, loose) {
		var result = listToArray(trim(comp), ' ');
		for (var i = 1; i <= arrayLen(result); i++){
			result[i] = replaceXRange(result[i]);
		}
		return arrayToList(result, ' ');
	}

	private function replaceXRange(comp, loose) {
		arguments.comp = trim(arguments.comp);
		var r = loose ? src[XRANGELOOSE] : src[XRANGE];
		var cleaner = function(ret, gtlt, Major, minor, patch, pre) {
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
		};
		return slipstream(comp, r, cleaner);
	}

	// Because * is AND-ed with everything else in the comparator,
	// and '' means "any version", just remove the *s entirely.
	private function replaceStars(comp, loose) {
		// Looseness is ignored here.  star is always as loose as it gets!
		return reReplace(trim(comp), re[STAR], '', 'ALL');
	}

	// This function is passed to string.replace(re[HYPHENRANGE])
	// M, m, patch, prerelease, build
	// 1.2 - 3.4.5 => >=1.2.0-0 <=3.4.5
	// 1.2.3 - 3.4 => >=1.2.0-0 <3.5.0-0 Any 3.4.x will do
	// 1.2 - 3.4 => >=1.2.0-0 <3.5.0-0
	private function hyphenReplace(from, fMaj, fMin, fp, fpr, fb, to, tMaj, tMin, tp, tpr, tb) {
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
	this.test = function(version) {
		if (!len(version)) return false;
		for (var i = 0; i < this.set.length; i++) {
			if (testSet(this.set[i], version))
			return true;
		}
		return false;
	};

	private function testSet(set, version){
		for (var i = 0; i < arrayLen(arguments.set); i++) {
//todo: what exactly is this testing?
			if (!set[i].test(version)) return false;
		}
		return true;
	}

	this.satisfies = function(version, range, loose) {
		try {
			range = new Range(range, loose);
		} catch (any er) {
			return false;
		}
		return range.test(version);
	}

	this.maxSatisfying = function(versions, range, loose) {
		//versions is an array of version strings
		var matches = arrayFilter(versions, function(v){ return satisfies(v, range, loose); });
		var sortedMatches = arraySort(matches, 'text', 'desc');
		return (arrayLen(sortedMatches) > 0 ? sortedMatches[1] : '');
	}

	private function validRange(range, loose) {
		try {
			// Return '*' instead of '' so that truthiness works.
			// This will throw if it's invalid anyway
			return new Range(range, loose).range;
		} catch (er) {
			return '';
		}
	}


	/*
	 * Additions: These methods are not ports
	 *********************************************/

	//this function (and reFindNoSuck) emulate the behavior of JavaScript's string.replace(pattern, fn) behavior
	private function slipstream(str, pattern, callback){
		var matches = reFindNoSuck(pattern, str);
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
