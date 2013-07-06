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
	function init(version, loose = false){
		if (isInstanceOf(arguments.version, "semver")){
			if (arguments.version.loose == arguments.loose){
				return arguments.version;
			}else{
				arguments.version = arguments.version.version;
			}
		}
		this.loose = arguments.loose;
		if (len(arguments.version)){
			var r = this.loose ? this.src[variables.LOOSE] : this.src[variables.FULL];
			var m = reMatch(r, trim(arguments.version));
			if (!arrayLen(m)){
				throw "Invalid version `#arguments.version#`";
			}
		}else{
			arguments.version = '*';
			var m = ['*','*','*'];
		}

		this.raw = arguments.version;

		//these are actually numbers
		if (find(".", m[1]) > 0){
			m = listToArray(m[1], '.');
		}
		this.major = val(m[1]);
		this.minor = val(m[2]);
		this.patch = val(listFirst(m[3], '-'));
		this.prerelease = listToArray(listFirst(listRest(m[3], '-'), '+'), '.'); //pre comes between a hyphen and a plus
		this.build = listToArray(listRest(m[3], '+'), '.'); //build comes after a hyphen and can be dot-delimited

		format();
// writeDump(var={v=this.version},label='semver constructor');

// writeDump(var=this.src[this.HYPHENRANGE],abort=true);

		return this;
	}

	function parse(version, loose = false){
		var r = loose ? src[LOOSE] : src[FULL];
		return (reFind(r, version) > 0) ? new semver(version, loose) : '';
	}

	function valid(version, loose = false){
		var v = this.parse(version, loose);
		return (v != '') ? v.version : v;
	}

	function clean(version, loose = false){
		//implementation is just a copy of valid, so reuse it
		return this.valid(version, loose);
	}

	function inspect(){
		return '<SemVer "' & this.version & '">';
	}

	function toString(){
		return this.version;
	}

	function compare(other){
		if (!isInstanceOf(arguments.other, "semver")){
			arguments.other = new semver(arguments.other, this.loose);
		}

		return this.compareMain(other) || this.comparePre(other);
	}

	function compareMain(other){
		if (!isInstanceOf(arguments.other, "semver")){
			arguments.other = new semver(arguments.other, this.loose);
		}

		return this.compareIdentifiers(this.major, other.major) ||
		       this.compareIdentifiers(this.minor, other.minor) ||
		       this.compareIdentifiers(this.patch, other.patch);
	}

	function comparePre(other){
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
	}

	//replaces the class method "inc"
	private function incSemver(version, release, loose = false){
		try {
			return new semver(version, loose)._inc(release).version;
		}catch (any e){
			return '';
		}
	}

	//port of the instance method
	function inc(version, release, loose = false){


		/*
			this is a kind of wonky way to cram 2 methods into one, since CF doesn't have prototypes
			if there are 3 arguments, shunt off to the private method; otherwise re-map arguments to
			the desired method signature & continue...
		*/
		//if there's more than one argument, hand the request off to
		if (arrayLen(arguments) >= 2){
			return incSemver(version, release, loose);
		}
		//re-wire as per above comment
		arguments.release = version;

		switch(arguments.release){
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

	function compareIdentifiers(a, b){
		var anum = isNumeric(a);
		var bnum = isNumeric(b);

		return (anum && !bnum) ? -1 :
		       (bnum && !anum) ?  1 :
		       (a < b)         ? -1 :
		       (a > b)         ?  1 :
		                          0;
	};

	function rcompareIdentifiers(a, b){
		return compareIdentifiers(b, a);
	};

	function compareSemvers(a, b, loose = false){
		return new semver(a, loose).compare(b);
	};

	function compareLoose(a, b){
		return compareSemvers(a, b, true);
	};

	function rcompare(a, b, loose = false){
		return compareSemvers(b, a, loose);
	};

	function sort(list, loose = false){
		var sorter = function(a, b){
			return this.compareSemvers(a, b, loose);
		};
		arraySort(list, sorter);
	};

	function rsort(list, loose = false){
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

	function cmp(a, op, b, loose = false){
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

	function format(){
		this.version = "#this.major#.#this.minor#.#this.patch#";
		if (arrayLen(this.prerelease)){
			this.version &= '-' & arrayToList(this.prerelease, '.');
		}
		return this.version;
	};

}
