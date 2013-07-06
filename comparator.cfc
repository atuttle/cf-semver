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

	//ported from constructor function Comparator()
	function init(comp, loose = false){
		if (isInstanceOf(comp, "comparator")){
			if (comp.loose == arguments.loose){
				return comp;
			}else{
				comp = comp.value;
			}
		}

		this.loose = arguments.loose;
		this.parse(comp);

		if (isStruct(this.semver) && structIsEmpty(this.semver)){
			this.value = '';
		}else{
			this.value = this.operator & this.semver.version;
		}

		return this;
	};

	function parse(comp){
		var r = this.loose ? this.src[COMPARATORLOOSE] : this.src[COMPARATOR];
		var tmp = comp;
		var m = reMatch(r, comp);

// writeDump(var=local,label='comparator parse');
		if (!arrayLen(m)){
			throw 'Invalid comparator: `#comp#`';
		}

		this.operator = '';
		arrayEach(['<=','>=','<','>','='], function(op){
			if (find(op, comp) > 0 && this.operator == ''){
				this.operator = op;
				tmp = replace(tmp, op, "");
			}
		});
		m = listToArray(tmp, '.-');
// writeDump(var=local,label='comparator parse');
		// if it literally is just '>' or '' then allow anything.
		if (arrayLen(m) <= 1){
			this.semver = ANY;
		}else{
			this.semver = new semver(tmp, this.loose);
// writeDump(var={semver=this.semver, comparator_loose=this.loose},label='comparator semver');

			// <1.2.3-rc DOES allow 1.2.3-beta (has prerelease)
			// >=1.2.3 DOES NOT allow 1.2.3-beta
			// <=1.2.3 DOES allow 1.2.3-beta
			// However, <1.2.3 does NOT allow 1.2.3-beta,
			// even though `1.2.3-beta < 1.2.3`
			// The assumption is that the 1.2.3 version has something you
			// *don't* want, so we push the prerelease down to the minimum.
			if (this.operator == '<' && !arrayLen(this.semver.prerelease)) {
				this.semver.prerelease = [0];
				this.semver.format();
			}
		}
	};

	function inspect(){
		return '<SemVer Comparator "' & this.value & '">';
	};

	function toString(){
		return this.value;
	};

	function test(version){
		return (isStruct(this.semver) && structIsEmpty(this.semver)) ? true : //if empty struct, that's the "any" flag
		       createObject("component","semver").cmp(arguments.version, this.operator, this.semver, this.loose);
	};

}
