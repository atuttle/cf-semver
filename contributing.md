# Contribution Guide

This module should be capable of one thing, and one thing only: Parsing, validating, and testing SemVer's and SemVer ranges.

## To-Do list

1. **Pass existing unit tests.** The code and unit tests have been ported to CFML but have not yet been completely shored up.
2. **Write Documentation.** Need to document every public method and their intended uses.

## Bug Reports

When reporting bugs please include, at a minimum, a simple example of your problem in the form of provided input, expected output, and the actual result. For example:

> testing:
>
>     semver.valid('1.0.0');
>
> expected:
>
>     '1.0.0'
>
> actual:
>
>     throws "Invalid version `1.0.0`"

If you could take it a step further and add your test case to the unit tests through a pull request, even better!
