<cfcomponent extends="mxunit.framework.TestCase"><cfscript>

	variables.semver = createObject("component", "semver");
	// variables.range = createObject("component", "range");

	//before suite
	function beforeTests(){}

	//before every test
	function setup(){}

	//after every test
	function tearDown(){}

	//after suite
	function afterTests(){}

	//--------------------------------

	function simple_contsructor_tests(){
		var a = new semver('1.0.0');
		var b = new semver(a);
		debug(a);
		debug(b);
		assertEquals(a.version, b.version);
	}

	function leading_characters_ignored_tests(){
		var a = new semver('v1.2.3');
		var b = new semver('=4.5.6');
		debug(a);
		debug(b);
		assertEquals('1.2.3', a.version);
		assertEquals('4.5.6', b.version);
	}

	function defaults_tests(){
		var a = new semver('1');
		debug(a);
		assertEquals(1, a.major);
		assertEquals(0, a.minor);
		assertEquals(0, a.patch);
	}

	function wildcard_tests(){
		var a = new semver('1.*.*');
		var b = new semver('*');
		var c = new semver('1.*');
		debug(a);
		assertEquals(1,   a.major);
		assertEquals('*', a.minor);
		assertEquals('*', a.patch);
		debug(b);
		assertEquals('*', b.major);
		assertEquals('*', b.minor);
		assertEquals('*', b.patch);
		debug(c);
		assertEquals(1, c.major);
		assertEquals('*', c.minor);
		assertEquals('*', c.patch);
	}

	function valid_tests(){
		arrayEach(
			[
				{ valid: true, version: '1.0.0' }
				,{ valid: true, version: 'v1.0.0' }
				,{ valid: true, version: '=1.0.0' }
				,{ valid: true, version: '1.0' }
				,{ valid: true, version: 'v1.0' }
				,{ valid: true, version: '=1.0' }
				,{ valid: true, version: '1' }
				,{ valid: true, version: 'v1' }
				,{ valid: true, version: '=1' }
				,{ valid: true, version: '*' }
				,{ valid: true, version: 'v*' }
				,{ valid: true, version: '=*' }
				,{ valid: true, version: '1.1.1-alpha1' }
				,{ valid: true, version: '1.1.1-alpha1+2121' }
				,{ valid: false, version: 'git@github.com:atuttle/Taffy.git' }
				,{ valid: false, version: 'https://github.com/atuttle/Taffy.git' }
				,{ valid: false, version: 'https://github.com/atuttle/Taffy' }
				,{ valid: false, version: '0.x' }
				,{ valid: false, version: '0.x-beta' }
				,{ valid: false, version: '0.x-beta+build3' }
			]
			, function(ver){
				if (ver.valid){
					assertTrue( semver.valid(ver.version), 'FAILED TRUE ASSERTION: #ver.version#' );
				}else{
					assertFalse( semver.valid(ver.version), 'FAILED FALSE ASSERTION: #ver.version#' );
				}
			}
		);
	}

/*
	function comparison_tests(){
		// [version1, version2]
		// version1 should be greater than version2
		arrayEach(
			[
				['0.0.0', '0.0.0-foo']
				,['0.0.1', '0.0.0']
				,['1.0.0', '0.9.9']
				,['0.10.0', '0.9.0']
				,['0.99.0', '0.10.0']
				,['2.0.0', '1.2.3']
				,['v0.0.0', '0.0.0-foo', true]
				,['v0.0.1', '0.0.0', true]
				,['v1.0.0', '0.9.9', true]
				,['v0.10.0', '0.9.0', true]
				,['v0.99.0', '0.10.0', true]
				,['v2.0.0', '1.2.3', true]
				,['0.0.0', 'v0.0.0-foo', true]
				,['0.0.1', 'v0.0.0', true]
				,['1.0.0', 'v0.9.9', true]
				,['0.10.0', 'v0.9.0', true]
				,['0.99.0', 'v0.10.0', true]
				,['2.0.0', 'v1.2.3', true]
				,['1.2.3', '1.2.3-asdf']
				,['1.2.3', '1.2.3-4']
				,['1.2.3', '1.2.3-4-foo']
				,['1.2.3-5-foo', '1.2.3-5']
				,['1.2.3-5', '1.2.3-4']
				,['1.2.3-5-foo', '1.2.3-5-Foo']
				,['3.0.0', '2.7.2+asdf']
				,['1.2.3-a.10', '1.2.3-a.5']
				,['1.2.3-a.b', '1.2.3-a.5']
				,['1.2.3-a.b', '1.2.3-a']
				,['1.2.3-a.b.c.10.d.5', '1.2.3-a.b.c.5.d.100']
	  		]
	  		,function(v){
				var v0 = v[1];
				var v1 = v[2];
				var loose = (arrayLen(v) >= 3) ? v[3] : false;
				debug('testing: v0=[#v0#], v1=[#v1#], loose=[#loose#]');
				assertTrue(semver.gt(v0, v1, loose), "gt('#v0#', '#v1#')");
				assertTrue(semver.lt(v1, v0, loose), "lt('#v1#', '#v0#')");
				assertTrue(!semver.gt(v1, v0, loose), "!gt('#v1#', '#v0#')");
				assertTrue(!semver.lt(v0, v1, loose), "!lt('#v0#', '#v1#')");
				assertTrue(semver.eq(v0, v0, loose), "eql('#v0#', '#v0#')");
				assertTrue(semver.eq(v1, v1, loose), "eql('#v1#', '#v1#')");
				assertTrue(semver.neq(v0, v1, loose), "neql('#v0#', '#v1#')");
				assertTrue(semver.cmp(v1, '==', v1, loose), "cmp('#v1#' == '#v1#')");
				assertTrue(semver.cmp(v0, '>=', v1, loose), "cmp('#v0#' >= '#v1#')");
				assertTrue(semver.cmp(v1, '<=', v0, loose), "cmp('#v1#' <= '#v0#')");
				assertTrue(semver.cmp(v0, '!=', v1, loose), "cmp('#v0#' != '#v1#')");
			}
	  	);
	}

	function equality_tests(){
		// [version1, version2]
		// version1 should be equivalent to version2
		arrayEach(
			[
				['1.2.3', 'v1.2.3', true]
				,['1.2.3', '=1.2.3', true]
				,['1.2.3', 'v 1.2.3', true]
				,['1.2.3', '= 1.2.3', true]
				,['1.2.3', ' v1.2.3', true]
				,['1.2.3', ' =1.2.3', true]
				,['1.2.3', ' v 1.2.3', true]
				,['1.2.3', ' = 1.2.3', true]
				,['1.2.3-0', 'v1.2.3-0', true]
				,['1.2.3-0', '=1.2.3-0', true]
				,['1.2.3-0', 'v 1.2.3-0', true]
				,['1.2.3-0', '= 1.2.3-0', true]
				,['1.2.3-0', ' v1.2.3-0', true]
				,['1.2.3-0', ' =1.2.3-0', true]
				,['1.2.3-0', ' v 1.2.3-0', true]
				,['1.2.3-0', ' = 1.2.3-0', true]
				,['1.2.3-1', 'v1.2.3-1', true]
				,['1.2.3-1', '=1.2.3-1', true]
				,['1.2.3-1', 'v 1.2.3-1', true]
				,['1.2.3-1', '= 1.2.3-1', true]
				,['1.2.3-1', ' v1.2.3-1', true]
				,['1.2.3-1', ' =1.2.3-1', true]
				,['1.2.3-1', ' v 1.2.3-1', true]
				,['1.2.3-1', ' = 1.2.3-1', true]
				,['1.2.3-beta', 'v1.2.3-beta', true]
				,['1.2.3-beta', '=1.2.3-beta', true]
				,['1.2.3-beta', 'v 1.2.3-beta', true]
				,['1.2.3-beta', '= 1.2.3-beta', true]
				,['1.2.3-beta', ' v1.2.3-beta', true]
				,['1.2.3-beta', ' =1.2.3-beta', true]
				,['1.2.3-beta', ' v 1.2.3-beta', true]
				,['1.2.3-beta', ' = 1.2.3-beta', true]
				,['1.2.3-beta+build', ' = 1.2.3-beta+otherbuild', true]
				,['1.2.3+build', ' = 1.2.3+otherbuild', true]
				,['1.2.3-beta+build', '1.2.3-beta+otherbuild']
				,['1.2.3+build', '1.2.3+otherbuild']
				,['  v1.2.3+build', '1.2.3+otherbuild']
			]
			,function(v){
				var v0 = v[1];
				var v1 = v[2];
				var loose = (arrayLen(v) >= 3) ? v[3] : false;
				debug('something');
				assertTrue(semver.eq(v0, v1, loose), "eq('#v0#', '#v1#')");
				assertTrue(!semver.neq(v0, v1, loose), "!neq('#v0#', '#v1#')");
				assertTrue(semver.cmp(v0, '==', v1, loose), 'cmp(#v0#==#v1#)');
				assertTrue(!semver.cmp(v0, '!=', v1, loose), '!cmp(#v0#!=#v1#)');
				assertTrue(!semver.cmp(v0, '===', v1, loose), '!cmp(#v0#===#v1#)');
				assertTrue(semver.cmp(v0, '!==', v1, loose), 'cmp(#v0#!==#v1#)');
				assertTrue(!semver.gt(v0, v1, loose), "!gt('#v0#', '#v1#')");
				assertTrue(semver.gte(v0, v1, loose), "gte('#v0#', '#v1#')");
				assertTrue(!semver.lt(v0, v1, loose), "!lt('#v0#', '#v1#')");
				assertTrue(semver.lte(v0, v1, loose), "lte('#v0#', '#v1#')");
			}
		);
	}

	function range_tests(){
		// [range, version]
		// version should be included by range
		arrayEach(
			[
				['1.0.0 - 2.0.0', '1.2.3']
				,['1.0.0', '1.0.0']
				,['>=*', '0.2.4']
				,['', '1.0.0']
				,['*', '1.2.3']
				,['*', 'v1.2.3-foo', true]
				,['>=1.0.0', '1.0.0']
				,['>=1.0.0', '1.0.1']
				,['>=1.0.0', '1.1.0']
				,['>1.0.0', '1.0.1']
				,['>1.0.0', '1.1.0']
				,['<=2.0.0', '2.0.0']
				,['<=2.0.0', '1.9999.9999']
				,['<=2.0.0', '0.2.9']
				,['<2.0.0', '1.9999.9999']
				,['<2.0.0', '0.2.9']
				,['>= 1.0.0', '1.0.0']
				,['>=  1.0.0', '1.0.1']
				,['>=   1.0.0', '1.1.0']
				,['> 1.0.0', '1.0.1']
				,['>  1.0.0', '1.1.0']
				,['<=   2.0.0', '2.0.0']
				,['<= 2.0.0', '1.9999.9999']
				,['<=  2.0.0', '0.2.9']
				,['<    2.0.0', '1.9999.9999']
				,['<	2.0.0', '0.2.9']
				,['>=0.1.97', 'v0.1.97', true]
				,['>=0.1.97', '0.1.97']
				,['0.1.20 || 1.2.4', '1.2.4']
				,['>=0.2.3 || <0.0.1', '0.0.0']
				,['>=0.2.3 || <0.0.1', '0.2.3']
				,['>=0.2.3 || <0.0.1', '0.2.4']
				,['||', '1.3.4']
				,['2.x.x', '2.1.3']
				,['1.2.x', '1.2.3']
				,['1.2.x || 2.x', '2.1.3']
				,['1.2.x || 2.x', '1.2.3']
				,['x', '1.2.3']
				,['2.*.*', '2.1.3']
				,['1.2.*', '1.2.3']
				,['1.2.* || 2.*', '2.1.3']
				,['1.2.* || 2.*', '1.2.3']
				,['*', '1.2.3']
				,['2', '2.1.2']
				,['2.3', '2.3.1']
				,['~2.4', '2.4.0'] // >=2.4.0 <2.5.0
				,['~2.4', '2.4.5']
				,['~>3.2.1', '3.2.2'] // >=3.2.1 <3.3.0
				,['~1', '1.2.3'] // >=1.0.0 <2.0.0
				,['~>1', '1.2.3']
				,['~> 1', '1.2.3']
				,['~1.0', '1.0.2'] // >=1.0.0 <1.1.0
				,['~ 1.0', '1.0.2']
				,['~ 1.0.3', '1.0.12']
				,['>=1', '1.0.0']
				,['>= 1', '1.0.0']
				,['<1.2', '1.1.1']
				,['< 1.2', '1.1.1']
				,['1', '1.0.0beta', true]
				,['~v0.5.4-pre', '0.5.5']
				,['~v0.5.4-pre', '0.5.4']
				,['=0.7.x', '0.7.2']
				,['>=0.7.x', '0.7.2']
				,['=0.7.x', '0.7.0-asdf']
				,['>=0.7.x', '0.7.0-asdf']
				,['<=0.7.x', '0.6.2']
				,['~1.2.1 >=1.2.3', '1.2.3']
				,['~1.2.1 =1.2.3', '1.2.3']
				,['~1.2.1 1.2.3', '1.2.3']
				,['~1.2.1 >=1.2.3 1.2.3', '1.2.3']
				,['~1.2.1 1.2.3 >=1.2.3', '1.2.3']
				,['~1.2.1 1.2.3', '1.2.3']
				,['>=1.2.1 1.2.3', '1.2.3']
				,['1.2.3 >=1.2.1', '1.2.3']
				,['>=1.2.3 >=1.2.1', '1.2.3']
				,['>=1.2.1 >=1.2.3', '1.2.3']
				,['<=1.2.3', '1.2.3-beta']
				,['>1.2', '1.3.0-beta']
				,['>=1.2', '1.2.8']
			]
			,function(v){
				var range = v[1];
				var ver = v[2];
				var loose = (arrayLen(v) >= 3) ? v[3] : false;
				debug('ver=[#ver#] range=[#range#] loose=[#loose#]');
				assertTrue(variables.range.satisfies(ver, range, loose), '"' & range & '" should be satisfied by "' & ver & '"');
			}
		);
	}

	function negative_range_tests(){
		// [range, version]
		// version should not be included by range
		arrayEach(
			[
				['1.0.0 - 2.0.0', '2.2.3']
				,['1.0.0', '1.0.1']
				,['>=1.0.0', '0.0.0']
				,['>=1.0.0', '0.0.1']
				,['>=1.0.0', '0.1.0']
				,['>1.0.0', '0.0.1']
				,['>1.0.0', '0.1.0']
				,['<=2.0.0', '3.0.0']
				,['<=2.0.0', '2.9999.9999']
				,['<=2.0.0', '2.2.9']
				,['<2.0.0', '2.9999.9999']
				,['<2.0.0', '2.2.9']
				,['>=0.1.97', 'v0.1.93', true]
				,['>=0.1.97', '0.1.93']
				,['0.1.20 || 1.2.4', '1.2.3']
				,['>=0.2.3 || <0.0.1', '0.0.3']
				,['>=0.2.3 || <0.0.1', '0.2.2']
				,['2.x.x', '1.1.3']
				,['2.x.x', '3.1.3']
				,['1.2.x', '1.3.3']
				,['1.2.x || 2.x', '3.1.3']
				,['1.2.x || 2.x', '1.1.3']
				,['2.*.*', '1.1.3']
				,['2.*.*', '3.1.3']
				,['1.2.*', '1.3.3']
				,['1.2.* || 2.*', '3.1.3']
				,['1.2.* || 2.*', '1.1.3']
				,['2', '1.1.2']
				,['2.3', '2.4.1']
				,['~2.4', '2.5.0'] // >=2.4.0 <2.5.0
				,['~2.4', '2.3.9']
				,['~>3.2.1', '3.3.2'] // >=3.2.1 <3.3.2
				,['~>3.2.1', '3.2.0'] // >=3.2.1 <3.3.0
				,['~1', '0.2.3'] // >=1.0.0 <2.0.0
				,['~>1', '2.2.3']
				,['~1.0', '1.1.0'] // >=1.0.0 <1.1.0
				,['<1', '1.0.0']
				,['>=1.2', '1.1.1']
				,['1', '2.0.0beta', true]
				,['~v0.5.4-beta', '0.5.4-alpha']
				,['<1', '1.0.0beta', true]
				,['< 1', '1.0.0beta', true]
				,['=0.7.x', '0.8.2']
				,['>=0.7.x', '0.6.2']
				,['<=0.7.x', '0.7.2']
				,['<1.2.3', '1.2.3-beta']
				,['=1.2.3', '1.2.3-beta']
				,['>1.2', '1.2.8']
				// invalid ranges never satisfied!
				,['blerg', '1.2.3']
			]
			,function(v){
				var range = v[1];
				var ver = v[2];
				var loose = (arrayLen(v) >= 3) ? v[3] : false;
				debug('ver=[' & ver & '] range=[' & range & '] loose=[' & loose & ']');
				assertTrue(!variables.range.satisfies(ver, range, loose), ver & ' should not satisfy range ' & range);
	    	}
		);
	}

	function increment_versions_tests(){
		// [version, inc, result]
		// inc(version, inc) -> result
		arrayEach(
			[
				['1.2.3', 'major', '2.0.0']
				,['1.2.3', 'minor', '1.3.0']
				,['1.2.3', 'patch', '1.2.4']
				,['1.2.3tag', 'major', '2.0.0', true]
				,['1.2.3-tag', 'major', '2.0.0']
				,['1.2.3', 'fake', '']
				,['fake', 'major', '']
				,['1.2.3', 'prerelease', '1.2.3-0']
				,['1.2.3-0', 'prerelease', '1.2.3-1']
				,['1.2.3-alpha.0', 'prerelease', '1.2.3-alpha.1']
				,['1.2.3-alpha.1', 'prerelease', '1.2.3-alpha.2']
				,['1.2.3-alpha.2', 'prerelease', '1.2.3-alpha.3']
				,['1.2.3-alpha.0.beta', 'prerelease', '1.2.3-alpha.1.beta']
				,['1.2.3-alpha.1.beta', 'prerelease', '1.2.3-alpha.2.beta']
				,['1.2.3-alpha.2.beta', 'prerelease', '1.2.3-alpha.3.beta']
				,['1.2.3-alpha.10.0.beta', 'prerelease', '1.2.3-alpha.10.1.beta']
				,['1.2.3-alpha.10.1.beta', 'prerelease', '1.2.3-alpha.10.2.beta']
				,['1.2.3-alpha.10.2.beta', 'prerelease', '1.2.3-alpha.10.3.beta']
				,['1.2.3-alpha.10.beta.0', 'prerelease', '1.2.3-alpha.10.beta.1']
				,['1.2.3-alpha.10.beta.1', 'prerelease', '1.2.3-alpha.10.beta.2']
				,['1.2.3-alpha.10.beta.2', 'prerelease', '1.2.3-alpha.10.beta.3']
				,['1.2.3-alpha.9.beta', 'prerelease', '1.2.3-alpha.10.beta']
				,['1.2.3-alpha.10.beta', 'prerelease', '1.2.3-alpha.11.beta']
				,['1.2.3-alpha.11.beta', 'prerelease', '1.2.3-alpha.12.beta']
			]
			,function(v){
				var pre = v[1];
				var what = v[2];
				var wanted = v[3];
				var loose = (arrayLen(v) >= 4) ? v[4] : false;
				var found = semver.inc(pre, what, loose);
				assertEquals(wanted, found, 'inc(' & pre & ', ' & what & ') === ' & wanted);
			}
		);
	}

	function valid_range_tests(){
		// [range, result]
		// validRange(range) -> result
		// translate ranges into their canonical form
		arrayEach(
			[
				['1.0.0 - 2.0.0', '>=1.0.0 <=2.0.0']
				,['1.0.0', '1.0.0']
				,['>=*', '>=0.0.0-0']
				,['', '*']
				,['*', '*']
				,['*', '*']
				,['>=1.0.0', '>=1.0.0']
				,['>1.0.0', '>1.0.0']
				,['<=2.0.0', '<=2.0.0']
				,['1', '>=1.0.0-0 <2.0.0-0']
				,['<=2.0.0', '<=2.0.0']
				,['<=2.0.0', '<=2.0.0']
				,['<2.0.0', '<2.0.0-0']
				,['<2.0.0', '<2.0.0-0']
				,['>= 1.0.0', '>=1.0.0']
				,['>=  1.0.0', '>=1.0.0']
				,['>=   1.0.0', '>=1.0.0']
				,['> 1.0.0', '>1.0.0']
				,['>  1.0.0', '>1.0.0']
				,['<=   2.0.0', '<=2.0.0']
				,['<= 2.0.0', '<=2.0.0']
				,['<=  2.0.0', '<=2.0.0']
				,['<    2.0.0', '<2.0.0-0']
				,['<	2.0.0', '<2.0.0-0']
				,['>=0.1.97', '>=0.1.97']
				,['>=0.1.97', '>=0.1.97']
				,['0.1.20 || 1.2.4', '0.1.20||1.2.4']
				,['>=0.2.3 || <0.0.1', '>=0.2.3||<0.0.1-0']
				,['>=0.2.3 || <0.0.1', '>=0.2.3||<0.0.1-0']
				,['>=0.2.3 || <0.0.1', '>=0.2.3||<0.0.1-0']
				,['||', '||']
				,['2.x.x', '>=2.0.0-0 <3.0.0-0']
				,['1.2.x', '>=1.2.0-0 <1.3.0-0']
				,['1.2.x || 2.x', '>=1.2.0-0 <1.3.0-0||>=2.0.0-0 <3.0.0-0']
				,['1.2.x || 2.x', '>=1.2.0-0 <1.3.0-0||>=2.0.0-0 <3.0.0-0']
				,['x', '*']
				,['2.*.*', '>=2.0.0-0 <3.0.0-0']
				,['1.2.*', '>=1.2.0-0 <1.3.0-0']
				,['1.2.* || 2.*', '>=1.2.0-0 <1.3.0-0||>=2.0.0-0 <3.0.0-0']
				,['*', '*']
				,['2', '>=2.0.0-0 <3.0.0-0']
				,['2.3', '>=2.3.0-0 <2.4.0-0']
				,['~2.4', '>=2.4.0-0 <2.5.0-0']
				,['~2.4', '>=2.4.0-0 <2.5.0-0']
				,['~>3.2.1', '>=3.2.1-0 <3.3.0-0']
				,['~1', '>=1.0.0-0 <2.0.0-0']
				,['~>1', '>=1.0.0-0 <2.0.0-0']
				,['~> 1', '>=1.0.0-0 <2.0.0-0']
				,['~1.0', '>=1.0.0-0 <1.1.0-0']
				,['~ 1.0', '>=1.0.0-0 <1.1.0-0']
				,['<1', '<1.0.0-0']
				,['< 1', '<1.0.0-0']
				,['>=1', '>=1.0.0-0']
				,['>= 1', '>=1.0.0-0']
				,['<1.2', '<1.2.0-0']
				,['< 1.2', '<1.2.0-0']
				,['1', '>=1.0.0-0 <2.0.0-0']
				,['>01.02.03', '>1.2.3', true]
				,['>01.02.03', '']
				,['~1.2.3beta', '>=1.2.3-beta <1.3.0-0', true]
				,['~1.2.3beta', '']
			]
			,function(v){
				var pre = v[1];
				var wanted = v[2];
				var loose = (arrayLen(v) >= 3) ? v[3] : false;
				var found = range.validRange(pre, loose);

				assertEquals(wanted, found, 'validRange(' & pre & ') == ' & wanted);
			}
		);
	}

	function comparators_tests(){
		// [range, comparators]
		// turn range into a set of individual comparators
		arrayEach(
			[
				['1.0.0 - 2.0.0', [['>=1.0.0', '<=2.0.0']]]
				,['1.0.0', [['1.0.0']]]
				,['>=*', [['>=0.0.0-0']]]
				,['', [['']]]
				,['*', [['']]]
				,['*', [['']]]
				,['>=1.0.0', [['>=1.0.0']]]
				,['>=1.0.0', [['>=1.0.0']]]
				,['>=1.0.0', [['>=1.0.0']]]
				,['>1.0.0', [['>1.0.0']]]
				,['>1.0.0', [['>1.0.0']]]
				,['<=2.0.0', [['<=2.0.0']]]
				,['1', [['>=1.0.0-0', '<2.0.0-0']]]
				,['<=2.0.0', [['<=2.0.0']]]
				,['<=2.0.0', [['<=2.0.0']]]
				,['<2.0.0', [['<2.0.0-0']]]
				,['<2.0.0', [['<2.0.0-0']]]
				,['>= 1.0.0', [['>=1.0.0']]]
				,['>=  1.0.0', [['>=1.0.0']]]
				,['>=   1.0.0', [['>=1.0.0']]]
				,['> 1.0.0', [['>1.0.0']]]
				,['>  1.0.0', [['>1.0.0']]]
				,['<=   2.0.0', [['<=2.0.0']]]
				,['<= 2.0.0', [['<=2.0.0']]]
				,['<=  2.0.0', [['<=2.0.0']]]
				,['<    2.0.0', [['<2.0.0-0']]]
				,['<\t2.0.0', [['<2.0.0-0']]]
				,['>=0.1.97', [['>=0.1.97']]]
				,['>=0.1.97', [['>=0.1.97']]]
				,['0.1.20 || 1.2.4', [['0.1.20'], ['1.2.4']]]
				,['>=0.2.3 || <0.0.1', [['>=0.2.3'], ['<0.0.1-0']]]
				,['>=0.2.3 || <0.0.1', [['>=0.2.3'], ['<0.0.1-0']]]
				,['>=0.2.3 || <0.0.1', [['>=0.2.3'], ['<0.0.1-0']]]
				,['||', [[''], ['']]]
				,['2.x.x', [['>=2.0.0-0', '<3.0.0-0']]]
				,['1.2.x', [['>=1.2.0-0', '<1.3.0-0']]]
				,['1.2.x || 2.x', [['>=1.2.0-0', '<1.3.0-0'], ['>=2.0.0-0', '<3.0.0-0']]]
				,['1.2.x || 2.x', [['>=1.2.0-0', '<1.3.0-0'], ['>=2.0.0-0', '<3.0.0-0']]]
				,['x', [['']]]
				,['2.*.*', [['>=2.0.0-0', '<3.0.0-0']]]
				,['1.2.*', [['>=1.2.0-0', '<1.3.0-0']]]
				,['1.2.* || 2.*', [['>=1.2.0-0', '<1.3.0-0'], ['>=2.0.0-0', '<3.0.0-0']]]
				,['1.2.* || 2.*', [['>=1.2.0-0', '<1.3.0-0'], ['>=2.0.0-0', '<3.0.0-0']]]
				,['*', [['']]]
				,['2', [['>=2.0.0-0', '<3.0.0-0']]]
				,['2.3', [['>=2.3.0-0', '<2.4.0-0']]]
				,['~2.4', [['>=2.4.0-0', '<2.5.0-0']]]
				,['~2.4', [['>=2.4.0-0', '<2.5.0-0']]]
				,['~>3.2.1', [['>=3.2.1-0', '<3.3.0-0']]]
				,['~1', [['>=1.0.0-0', '<2.0.0-0']]]
				,['~>1', [['>=1.0.0-0', '<2.0.0-0']]]
				,['~> 1', [['>=1.0.0-0', '<2.0.0-0']]]
				,['~1.0', [['>=1.0.0-0', '<1.1.0-0']]]
				,['~ 1.0', [['>=1.0.0-0', '<1.1.0-0']]]
				,['~ 1.0.3', [['>=1.0.3-0', '<1.1.0-0']]]
				,['~> 1.0.3', [['>=1.0.3-0', '<1.1.0-0']]]
				,['<1', [['<1.0.0-0']]]
				,['< 1', [['<1.0.0-0']]]
				,['>=1', [['>=1.0.0-0']]]
				,['>= 1', [['>=1.0.0-0']]]
				,['<1.2', [['<1.2.0-0']]]
				,['< 1.2', [['<1.2.0-0']]]
				,['1', [['>=1.0.0-0', '<2.0.0-0']]]
				,['1 2', [['>=1.0.0-0', '<2.0.0-0', '>=2.0.0-0', '<3.0.0-0']]]
				,['1.2 - 3.4.5', [['>=1.2.0-0', '<=3.4.5']]]
				,['1.2.3 - 3.4', [['>=1.2.3', '<3.5.0-0']]]
			]
			,function(v){
				var pre = v[1];
				var wanted = v[2];
				var found = semver.toComparators(v[1]);
				var jw = serializeJson(wanted);
				assertEquals(wanted, found, 'toComparators(' & pre & ') === ' & jw);
			}
		);
	}

	function strict_vs_loose_version_numbers_tests(){
		arrayEach(
			[
				['=1.2.3', '1.2.3']
				,['01.02.03', '1.2.3']
				,['1.2.3-beta.01', '1.2.3-beta.1']
				,['   =1.2.3', '1.2.3']
				,['1.2.3foo', '1.2.3-foo']
			]
			,function(v){
				var loose = v[1];
				var strict = v[2];
				try{
					new semver(loose);
					fail('expected throw for semver.semver("#loose#")');
				}catch(any e){
					//don't fail, expected throw
				}
				var lv = new semver(loose, true);
				assertEquals(strict, lv.version);
				assertTrue(semver.eq(loose, strict, true));
				try{
					semver.eq(loose, strict);
					fail('expected throw for semver.eq("#loose#","#strict#")');
				}catch(any e){
					//don't fail, expected throw
				}
				try{
					semver.compare(new semver(strict), loose);
					fail('expected throw for semver.compare(semver.semver("#strict#"), "#loose#")');
				}catch(any e){
					//don't fail, expected throw
				}
			}
  		);
	}

	function strict_vs_loose_ranges_tests(){
		arrayEach(
			[
				['>=01.02.03', '>=1.2.3']
				,['~1.02.03beta', '>=1.2.3-beta <1.3.0-0']
			]
			,function(v){
				var loose = v[1];
				var comps = v[2];
				try{
					semver.Range(loose);
					fail('expected throw for semver.Range("#loose#")');
				}catch(any e){
					//don't fail, expected throw
				}
				assertEquals(comps, semver.Range(loose, true).range);
			}
		);
	}

	function max_satisfying_tests(){
		arrayEach(
			[
				[['1.2.3', '1.2.4'], '1.2', '1.2.4']
				,[['1.2.4', '1.2.3'], '1.2', '1.2.4']
				,[['1.2.3','1.2.4','1.2.5','1.2.6'], '~1.2.3', '1.2.6']
			]
			,function(v){
				var versions = v[1];
				var range = v[2];
				var expect = v[3];
				var loose = (arrayLen(v) >= 4) ? v[4] : false;
				var actual = semver.maxSatisfying(versions, range, loose);
				assertEquals(expect, actual);
			}
		);
	}
*/

</cfscript></cfcomponent>
