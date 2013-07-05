/*
	This CFC is mostly a port (with CF-specific updates) of the Node.js semver package, by Isaac Schlueter @izs

	I can't take credit for anything genius within, but I do claim ownership of port-specific bugs!

	The original module was available under the BSD license, therefore this port will also use the BSD license.
	http://opensource.org/licenses/BSD-3-Clause
*/
component {

	// Note: this is the semver.org version of the spec that it implements
	// Not necessarily the package version of this code.
	this.SEMVER_SPEC_VERSION = "2.0.0";

	//regexes
	this.re = [];
	this.src = [];
	variables.R = 1;
	variables.ANY = {};

	// The following Regular Expressions can be used for tokenizing,
	// validating, and parsing SemVer version strings.

	// ## Numeric Identifier
	// A single `0`, or a non-zero digit followed by zero or more digits.

	NUMERICIDENTIFIER = R++;
	this.src[NUMERICIDENTIFIER] = '0|[1-9]\d*';
	NUMERICIDENTIFIERLOOSE = R++;
	this.src[NUMERICIDENTIFIERLOOSE] = '[0-9]+';


	// ## Non-numeric Identifier
	// Zero or more digits, followed by a letter or hyphen, and then zero or
	// more letters, digits, or hyphens.

	NONNUMERICIDENTIFIER = R++;
	this.src[NONNUMERICIDENTIFIER] = '\d*[a-zA-Z-][a-zA-Z0-9-]*';


	// ## Main Version
	// Three dot-separated numeric identifiers.

	MAINVERSION = R++;
	this.src[MAINVERSION] = '(' & this.src[NUMERICIDENTIFIER] & ')\.' &
	                        '(' & this.src[NUMERICIDENTIFIER] & ')\.' &
	                        '(' & this.src[NUMERICIDENTIFIER] & ')';

	MAINVERSIONLOOSE = R++;
	this.src[MAINVERSIONLOOSE] = '(' & this.src[NUMERICIDENTIFIERLOOSE] & ')\.' &
	                                  '(' & this.src[NUMERICIDENTIFIERLOOSE] & ')\.' &
	                                  '(' & this.src[NUMERICIDENTIFIERLOOSE] & ')';


	// ## Pre-release Version Identifier
	// A numeric identifier, or a non-numeric identifier.

	PRERELEASEIDENTIFIER = R++;
	this.src[PRERELEASEIDENTIFIER] = '(?:' & this.src[NUMERICIDENTIFIER] &
	                                      '|' & this.src[NONNUMERICIDENTIFIER] & ')';

	PRERELEASEIDENTIFIERLOOSE = R++;
	this.src[PRERELEASEIDENTIFIERLOOSE] = '(?:' & this.src[NUMERICIDENTIFIERLOOSE] &
	                                           '|' & this.src[NONNUMERICIDENTIFIER] & ')';


	// ## Pre-release Version
	// Hyphen, followed by one or more dot-separated pre-release version
	// identifiers.

	PRERELEASE = R++;
	this.src[PRERELEASE] = '(?:-(' & this.src[PRERELEASEIDENTIFIER] &
	                       '(?:\.' & this.src[PRERELEASEIDENTIFIER] & ')*))';

	PRERELEASELOOSE = R++;
	this.src[PRERELEASELOOSE] = '(?:-?(' & this.src[PRERELEASEIDENTIFIERLOOSE] &
	                            '(?:\.' & this.src[PRERELEASEIDENTIFIERLOOSE] & ')*))';


	// ## Build Metadata Identifier
	// Any combination of digits, letters, or hyphens.

	BUILDIDENTIFIER = R++;
	this.src[BUILDIDENTIFIER] = '[0-9A-Za-z-]+';

	// ## Build Metadata
	// Plus sign, followed by one or more period-separated build metadata
	// identifiers.

	BUILD = R++;
	this.src[BUILD] = '(?:\+(' & this.src[BUILDIDENTIFIER] &
	                  '(?:\.' & this.src[BUILDIDENTIFIER] & ')*))';


	// ## Full Version String
	// A main version, followed optionally by a pre-release version and
	// build metadata.

	// Note that the only major, minor, patch, and pre-release sections of
	// the version string are capturing groups.  The build metadata is not a
	// capturing group, because it should not ever be used in version
	// comparison.

	FULL = R++;
	FULLPLAIN = 'v?' & this.src[MAINVERSION] &
	                   this.src[PRERELEASE] & '?' &
	                   this.src[BUILD] & '?';

	this.src[FULL] = '^' & FULLPLAIN & '$';


	// like full, but allows v1.2.3 and =1.2.3, which people do sometimes.
	// also, 1.0.0alpha1 (prerelease without the hyphen) which is pretty
	// common in the npm registry.
	LOOSEPLAIN = '[v=\s]*' & this.src[MAINVERSIONLOOSE] &
	                         this.src[PRERELEASELOOSE] & '?' &
	                         this.src[BUILD] & '?';

	LOOSE = R++;
	this.src[LOOSE] = '^' & LOOSEPLAIN & '$';

	GTLT = R++;
	this.src[GTLT] = '((?:<|>)?=?)';


	// Something like "2.*" or "1.2.x".
	// Note that "x.x" is a valid xRange identifer, meaning "any version"
	// Only the first item is strictly required.
	XRANGEIDENTIFIERLOOSE = R++;
	this.src[XRANGEIDENTIFIERLOOSE] = this.src[NUMERICIDENTIFIERLOOSE] & '|x|X|\*';
	XRANGEIDENTIFIER = R++;
	this.src[XRANGEIDENTIFIER] = this.src[NUMERICIDENTIFIER] & '|x|X|\*';

	XRANGEPLAIN = R++;
	this.src[XRANGEPLAIN] = '[v=\s]*(' & this.src[XRANGEIDENTIFIER] & ')' &
	                             '(?:\.(' & this.src[XRANGEIDENTIFIER] & ')' &
	                             '(?:\.(' & this.src[XRANGEIDENTIFIER] & ')' &
	                             '(?:(' & this.src[PRERELEASE] & ')' &
	                             ')?)?)?';

	XRANGEPLAINLOOSE = R++;
	this.src[XRANGEPLAINLOOSE] = '[v=\s]*(' & this.src[XRANGEIDENTIFIERLOOSE] & ')' &
	                                  '(?:\.(' & this.src[XRANGEIDENTIFIERLOOSE] & ')' &
	                                  '(?:\.(' & this.src[XRANGEIDENTIFIERLOOSE] & ')' &
	                                  '(?:(' & this.src[PRERELEASELOOSE] & ')' &
	                                  ')?)?)?';


	// >=2.x, for example, means >=2.0.0-0
	// <1.x would be the same as "<1.0.0-0", though.
	XRANGE = R++;
	this.src[XRANGE] = '^' & this.src[GTLT] & '\s*' & this.src[XRANGEPLAIN] & '$';
	XRANGELOOSE = R++;
	this.src[XRANGELOOSE] = '^' & this.src[GTLT] & '\s*' & this.src[XRANGEPLAINLOOSE] & '$';

	// Tilde ranges.
	// Meaning is "reasonably at or greater than"
	LONETILDE = R++;
	this.src[LONETILDE] = '(?:~>?)';

	TILDETRIM = R++;
	this.src[TILDETRIM] = this.src[LONETILDE] & '\s+';
	tildeTrimReplace = '$1';

	TILDE = R++;
	this.src[TILDE] = '^' & this.src[LONETILDE] & this.src[XRANGEPLAIN] & '$';
	TILDELOOSE = R++;
	this.src[TILDELOOSE] = '^' & this.src[LONETILDE] & this.src[XRANGEPLAINLOOSE] & '$';


	// A simple gt/lt/eq thing, or just "" to indicate "any version"
	COMPARATORLOOSE = R++;
	this.src[COMPARATORLOOSE] = '^' & this.src[GTLT] & '\s*(' & LOOSEPLAIN & ')$|^$';
	COMPARATOR = R++;
	this.src[COMPARATOR] = '^' & this.src[GTLT] & '\s*(' & FULLPLAIN & ')$|^$';


	// An expression to strip any whitespace between the gtlt and the thing
	// it modifies, so that `> 1.2.3` ==> `>1.2.3`
	COMPARATORTRIM = R++;
	this.src[COMPARATORTRIM] = this.src[GTLT] &
	                      '\s*(' & LOOSEPLAIN & '|' & this.src[XRANGEPLAIN] & ')';

	// this one has to use the /g flag
	//TODO: not sure CF supports flags on regexes; not sure what the consequences of this are...
	this.re[COMPARATORTRIM] = 'g';


	// Something like `1.2.3 - 1.2.4`
	// Note that these all use the loose form, because they'll be
	// checked against either the strict or loose comparator form
	// later.
	HYPHENRANGE = R++;
	this.src[HYPHENRANGE] = '^\s*(' & this.src[XRANGEPLAIN] & ')' &
	                   '\s+-\s+' &
	                   '(' & this.src[XRANGEPLAIN] & ')' &
	                   '\s*$';

	HYPHENRANGELOOSE = R++;
	this.src[HYPHENRANGELOOSE] = '^\s*(' & this.src[XRANGEPLAINLOOSE] & ')' &
	                        '\s+-\s+' &
	                        '(' & this.src[XRANGEPLAINLOOSE] & ')' &
	                        '\s*$';

	// Star ranges basically just allow anything at all.
	STAR = R++;
	this.src[STAR] = '(<|>)?=?\s*\*';

}
