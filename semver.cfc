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

	//ported from function SemVer()
	this.init = function(version, loose = false){
		if (isInstanceOf(arguments.version, "semver")){
			if (arguments.version.loose == arguments.loose){
				return arguments.version;
			}else{
				arguments.version = arguments.version.version;
			}
		}

		this.loose = arguments.loose;
		var r = this.loose ? this.src[this.LOOSE] : this.src[this.FULL];
		var m = reMatch(r, trim(arguments.version));
		if (!arrayLen(m)){
			throw "Invalid version `#arguments.version#`";
		}

		this.raw = arguments.version;

		//these are actually numbers
		// m = listToArray(m[1], '.-');
		this.major = val(m[1]);
		this.minor = val(m[2]);
		this.patch = val(m[3]);

		// numberify any prerelease numeric ids
		if (arrayLen(m) < 4){
			this.prerelease = [];
		}else{
			this.prerelease = listToArray(m[4], '.');
			for(var i = 1; i <= arrayLen(this.prerelease); i++){
				this.prerelease[i] = (isNumeric(this.prerelease[i]) ? val(this.prerelease[i]) : this.prerelease[i]);
			}
		}

		this.build = (arrayLen(m) >=5) ? listToArray(m[5], '.') : [];
		format();

// writeDump(var=this.src[this.HYPHENRANGE],abort=true);

		return this;
	};

	this.Parse = function(version, loose = false){
		var r = loose ? src[LOOSE] : src[FULL];
		return (reFind(r, version) > 0) ? new semver(version, loose) : '';
	};

	this.valid = function(version, loose = false){
		var v = this.parse(version, loose);
		return (v != '') ? v.version : v;
	};

	this.clean = function(version, loose = false){
		//implementation is just a copy of valid, so reuse it
		return this.valid(version, loose);
	};

	this.inspect = function(){
		return '<SemVer "' & this.version & '">';
	};

	this.toString = function(){
		return this.version;
	};

	this.compare = function(other){
		if (!isInstanceOf(arguments.other, "semver")){
			arguments.other = new semver(arguments.other, this.loose);
		}

		return this.compareMain(other) || this.comparePre(other);
	};

	this.compareMain = function(other){
		if (!isInstanceOf(arguments.other, "semver")){
			arguments.other = new semver(arguments.other, this.loose);
		}

		return this.compareIdentifiers(this.major, other.major) ||
		       this.compareIdentifiers(this.minor, other.minor) ||
		       this.compareIdentifiers(this.patch, other.patch);
	};

	this.comparePre = function(other){
		if (!isInstanceOf(arguments.other, "semver")){
			arguments.other = new semver(arguments.other, this.loose);
		}

		// NOT having a prerelease is > having one
		thisPre = arrayLen(this.prerelease);
		thatPre = arrayLen(other.prerelease);
		if (thisPre && !thatPre) return -1;
		else if (!thisPre && thatPre) return 1;
		else if (!thisPre && !thatPre) return 0;

		var i = 0;
		do {
			i++;
			if (thisPre < i && thatPre < i) return 0;
			else if (thatPre < i) return 1;
			else if (thisPre < i) return -1;
			else {
				var a = this.prerelease[i];
				var b = other.prerelease[i];
				if (a == b){
					continue;
				}else{
					return compareIdentifiers(a, b);
				}
			}
		} while(true);
	};

	//replaces the class method "inc"
	this.incSemver = function(version, release, loose = false){
		try {
			return new semver(version, loose)._inc(release).version;
		}catch (any e){
			return '';
		}
	};

	//port of the instance method
	this.inc = function(release){
		switch(release){
			case "major":
				this.major++;
				this.minor = -1;
				//intentionally omit break to cause cascade from entry point
			case "minor":
				this.minor++;
				this.patch = -1;
				//intentionally omit break to cause cascade from entry point
			case "patch":
				this.patch++;
				this.prerelease = [];
				break;
			case "prerelease":
				if (arrayLen(this.prerelease) == 0) {
					this.prerelease = [0];
				}else{
					var i = arrayLen(this.prerelease);
					while (--i >= 0) {
						if (isNumeric(this.prerelease[i])) {
							this.prerelease[i]++;
							i = -2;
						}
					}
					if (i == -1) { // didn't increment anything
						arrayAppend(this.prerelease, 0);
					}
				}
				break;
			default:
				throw "Invalid increment argument: `#arguments.release#`";
		}
		this.format();
		return this;
	};

	this.compareIdentifiers = function(a, b){
		var anum = isNumeric(a);
		var bnum = isNumeric(b);

		return (anum && !bnum) ? -1 :
		       (bnum && !anum) ?  1 :
		       (a < b)         ? -1 :
		       (a > b)         ?  1 :
		                          0;
	};

	this.rcompareIdentifiers = function(a, b){
		return compareIdentifiers(b, a);
	};

	this.compareSemvers = function(a, b, loose = false){
		return new semver(a, loose).compare(b);
	};

	this.compareLoose = function(a, b){
		return compareSemvers(a, b, true);
	};

	this.rcompare = function(a, b, loose = false){
		return compareSemvers(b, a, loose);
	};

	this.sort = function(list, loose = false){
		var sorter = function(a, b){
			return this.compareSemvers(a, b, loose);
		};
		arraySort(list, sorter);
	};

	this.rsort = function(list, loose = false){
		var sorter = function(a, b){
			return rcompare(a, b, loose);
		};
	};

	this.gt = function(a, b, loose = false){
		return this.compareSemvers(a, b, loose) > 0;
	};

	this.lt = function(a, b, loose = false){
		return this.compareSemvers(a, b, loose) < 0;
	};

	this.eq = function(a, b, loose = false){
		return this.compareSemvers(a, b, loose) == 0;
	};

	this.neq = function(a, b, loose = false){
		return this.compareSemvers(a, b, loose) != 0;
	};

	this.gte = function(a, b, loose = false){
		return this.compareSemvers(a, b, loose) >= 0;
	};

	this.lte = function(a, b, loose = false){
		return this.compareSemvers(a, b, loose) <= 0;
	};

	this.cmp = function(a, op, b, loose = false){
		var ret = '';
		switch(op){
			case '===': ret = this.eq(a, b); break;
			case '!==': ret = this.neq(a, b); break;
			case '': case '=': case '==': ret = this.eq(a, b, loose); break;
			case '!=': ret = this.neq(a, b, loose); break;
			case '>':  ret = this.gt(a, b, loose); break;
			case '>=': ret = this.gte(a, b, loose); break;
			case '<':  ret = this.lt(a, b, loose); break;
			case '<=': ret = this.lte(a, b, loose); break;
			default: throw "Invalid operator `#op#`";
		}
		return ret;
	};

	this.satisfies = function(){ return false; };

	this.replaceStars = function(){ return false; };

	this.toComparators = function(){ return false; };

	this.maxSatisfying = function(){ return false; };

	/*
	 * PRIVATE METHODS
	 */

	variables.format = function(){
		this.version = "#this.major#.#this.minor#.#this.patch#";
		if (arrayLen(this.prerelease)){
			this.version &= '-' & arrayToList(this.prerelease, '.');
		}
		return this.version;
	};

}
