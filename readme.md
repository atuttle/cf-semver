# SemVer

Semantic Version parsing, management, etc for CFML. Specified by and conforms to the [SemVer 2.0.0 specification](http://semver.org/spec/v2.0.0.html).

##TL;DR:

**major.minor.patch-prerelease+build**

* major, minor, patch: numeric
* prerelease, build: alphanumeric (though apparently some people choose to use a major.minor.patch in the prerelease string?)

---

* Breaking changes, major additions: increment Major
* New minor features: increment Minor
* Bug fixes: increment patch

**0.\*.\*** is considered volatile and may include breaking changes between minor or patch versions.

A prerelease string (any value) is considered a lower version than the same version number with no pre string. Thus: `0.0.1` > `0.0.1-beta`.

Prerelease/build strings are compared alphanumerically; thus:

* `1.0.0-alpha1` < `1.0.0-alpha2` < `1.0.0-beta` < `1.0.0`
* `v1.1.1-aaa` > `v1.1.1-aa` (longer string is greater if common characters are equal)
* `v1.1.1-aaa` < `v1.1.1-aba` (`b` > `a`)
* `2.0.0-10` < `2.0.0-5` (`1` < `5`)

### Prefixes

A leading `v` or `=` will be stripped and ignored, e.g. `v2.3.0`

### Wildcards

An asterisk `*` is acceptable for any value in the semver string: `1.2.*`

## Ranges

TBD

## Contributing

Want to help out? Found a bug? Great! Check out [the Contribution Guide](https://github.com/atuttle/cf-semver/blob/master/contributing.md#contribution-guide).

## Contributors

* [Adam Tuttle](http://github.com/atuttle/)

## License

Freely available under the MIT License.

> Copyright (c) 2013 Adam Tuttle and Contributors
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
> THE SOFTWARE.
