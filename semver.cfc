component {

	this.semver_spec_version = '2.0.0';

	this.major = 0;
	this.minor = 0;
	this.patch = 0;
	this.pre = '';
	this.build = '';
	this.raw = '';

	function init(version){
		//if passed another semver object as the version string, just return that semver object
		if (isInstanceOf(arguments.version, "semver")){
			return arguments.version;
		}
		arguments.version = trim(arguments.version);
		if (!len(arguments.version)){
			throw "InvalidSemverException";
		}

		var parsedVersion = parse(arguments.version);
		this.major = parsedVersion[1];
		this.minor = parsedVersion[2];
		this.patch = parsedVersion[3];
		this.pre   = parsedVersion[4];
		this.build = parsedVersion[5];

		this.raw = arguments.version;
		format();
		return this;
	}

	function parse(versionString){
		var v = arguments.versionString;
		var MAJOR = -1;
		var MINOR = -1;
		var PATCH = -1;
		var PRE = '';
		var BUILD = '';

		//strip ignorable characters
		if (left(v, 1) == "v" || left(v, 1) == "="){
			v = right(v, len(v)-1);
		}
		//save the prerelease string
		PRE = listRest(v, '-+');
		BUILD = listRest(PRE, '+');
		PRE = listFirst(PRE, '+');
		//split into major.minor.patch values
		var blocks = listToArray(v, '-+');
		var versions = listToArray(blocks[1], '.');
		if (isNumeric(versions[1])){
			MAJOR = val( versions[1] );
		}else if (versions[1] == '*'){
			MAJOR = '*';
			MINOR = '*';
			PATCH = '*';
		}else{
			throw "InvalidSemverException";
		}
		if (MINOR == -1){
			if (arrayLen(versions) > 1){
				if (versions[2] == '*'){
					MINOR = '*';
					PATCH = '*';
				}else if ( isNumeric(versions[2]) ){
					MINOR = val( versions[2] );
				}else{
					throw "InvalidSemverException";
				}
			}else{
				MINOR = 0;
				PATCH = 0;
			}
		}
		if (PATCH == -1){
			if (arrayLen(versions) > 2){
				if (versions[3] == '*'){
					PATCH = '*';
				}else if ( isNumeric(versions[3]) ){
					PATCH = val( versions[3] );
				}else{
					throw "InvalidSemverException";
				}
			}else{
				PATCH = 0;
			}
		}
		return [MAJOR, MINOR, PATCH, PRE, BUILD];
	}

	function format(){
		this.version = '#this.major#.#this.minor#.#this.patch#'
		               & (len(this.pre)   ? '-#this.pre#'   : '')
		               & (len(this.build) ? '+#this.build#' : '');
	}

	function valid(version){
		try{
			var v = parse(version);
			return '#v[1]#.#v[2]#.#v[3]#'
	               & (len(v[4]) ? '-#v[4]#' : '')
	               & (len(v[5]) ? '+#v[5]#' : '');
		}catch(any e){
			return false;
		}
	}

	function toString(){
		return this.version;
	}

	function compare(v1, v2){
		if (!isInstanceOf(arguments.v1, "semver")){
			arguments.v1 = new semver(arguments.v1);
		}
		if (!isInstanceOf(arguments.v2, "semver")){
			arguments.v2 = new semver(arguments.v2);
		}

		var mainCompare = compareMain(arguments.v1, arguments.v2);
		if (mainCompare != 0){
			return mainCompare;
		}else{
			//version numbers match, compare pre-strings
			return comparePre(v1, v2);
		}
	}

	function rcompare(v1, v2){
		return compare(v2, v1);
	}

	function compareMain(v1, v2){
		return compareIdentifiers(v1.major, v2.major) ||
		       compareIdentifiers(v1.minor, v2.minor) ||
		       compareIdentifiers(v1.patch, v2.patch);
	}

	function comparePre(v1, v2){
		// NOT having a prerelease is > having one
		var v1pre_a = listToArray(v1.pre, "");
		var v2pre_a = listToArray(v2.pre, "");
		var v1pre = arrayLen(v1pre_a);
		var v2pre = arrayLen(v2pre_a);
		if (v1pre && !v2pre) return -1;
		else if (!v1pre && v2pre) return 1;
		else if (!v1pre && !v2pre) return compareMain(v1, v2);

		//if they both have pre's, compare the pre
		var i = 0;
		do {
			i++;
			//equal length (zero+) pre strings that have matched up to this point & are both out of more chars
			if (v1pre < i && v2pre < i) return 0;
			//v1 is longer
			else if (v2pre < i) return 1;
			//v2 is longer
			else if (v1pre < i) return -1;
			//alphanumeric pre
			else {
				var a = asc( v1pre_a[i] );
				var b = asc( v2pre_a[i] );
				var comparison = compareIdentifiers(a, b);
				if (comparison == 0){
					continue;
				}else{
					return comparison;
				}
			}
		} while(true);
	}

	private function compareIdentifiers(a, b){
		return (a < b) ? -1 :
		       (a > b) ?  1 :
		                  0;
	}

	/*
		Pass 1 argument to increment this instance of a semver;
		Pass 2 arguments to create a new semver and increment it
	*/
	function inc(release, version){
		if (arrayLen(arguments) == 2){
			return new semver(version).inc(release);
		}
		switch(trim(lcase(arguments.release))){
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
			default:
				throw "Invalid increment argument: `#arguments.release#`; Expects one of: (major, minor, patch)";
		}
		format();
		return this;
	}

	/******************************************************************************************************************
	 *	Use this odd (to CF) function declaration syntax so we can overload 1st class function names like EQ and GTE
	 *    this.x = function( ... ){ ... }
	 *****************************************************************************************************************/

	/*
		Pass 1 argument to compare this > arg
		Pass 2 arguments to compare left > right
	*/
	this.gt = function(a, b = '**null**'){
		if (isSimpleValue(b) && b == '**null**'){
			b = duplicate(a);
			a = this.version;
		}
		return this.compare(a, b) > 0;
	};

	/*
		Pass 1 argument to compare this < arg
		Pass 2 arguments to compare left < right
	*/
	this.lt = function(a, b = '**null**'){
		if (isSimpleValue(b) && b == '**null**'){
			b = duplicate(a);
			a = this.version;
		}
		return this.compare(a, b) < 0;
	};

	/*
		Pass 1 argument to compare this == arg
		Pass 2 arguments to compare left == right
	*/
	this.eq = function(a, b = '**null**'){
		if (isSimpleValue(b) && b == '**null**'){
			b = duplicate(a);
			a = this.version;
		}
		return compare(a, b) == 0;
	};

	/*
		Pass 1 argument to compare this != arg
		Pass 2 arguments to compare left != right
	*/
	this.neq = function(a, b = '**null**'){
		if (isSimpleValue(b) && b == '**null**'){
			b = duplicate(a);
			a = this.version;
		}
		return compare(a, b) != 0;
	};

	/*
		Pass 1 argument to compare this >= arg
		Pass 2 arguments to compare left >= right
	*/
	this.gte = function(a, b = '**null**'){
		if (isSimpleValue(b) && b == '**null**'){
			b = duplicate(a);
			a = this.version;
		}
		return compare(a, b) >= 0;
	};

	/*
		Pass 1 argument to compare this <= arg
		Pass 2 arguments to compare left <= right
	*/
	this.lte = function(a, b = '**null**'){
		if (isSimpleValue(b) && b == '**null**'){
			b = duplicate(a);
			a = this.version;
		}
		return compare(a, b) <= 0;
	};


/*
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
*/

}
