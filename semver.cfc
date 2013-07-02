<cfcomponent><cfscript>

	this.SEMVER_SPEC_VERSION = "2.0.0";

	//use this odd (to CF) function declaration syntax so we can overload 1st class function names
	this.eq = function(){ return false; };

	this.gt = function(){ return false; };

	this.lt = function(){ return false; };

	this.neq = function(){ return false; };

	this.cmp = function(){ return false; };

	this.gte = function(){ return false; };

	this.lte = function(){ return false; };

	this.satisfies = function(){ return false; };

	this.validRange = function(){ return false; };

	this.inc = function(){ return false; };

	this.replaceStars = function(){ return false; };

	this.toComparators = function(){ return false; };

	this.SemVer = function(){ return false; };

	this.Range = function(){ return false; };

	this.Parse = function(){ return false; };

	this.valid = function(){ return false; };

	this.clean = function(){ return false; };

	this.compareIdentifiers = function(){ return false; };

	this.rcompareIdentifiers = function(){ return false; };

	this.compare = function(){ return false; };

	this.compareLoose = function(){ return false; };

	this.rcompare = function(){ return false; };

	this.sort = function(){ return false; };

	this.rsort = function(){ return false; };

	this.Comparator = function(){ return false; };

	this.maxSatisfying = function(){ return false; };

</cfscript></cfcomponent>