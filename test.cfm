<cfinvoke component="mxunit.runner.DirectoryTestSuite"
          method="run"
          directory="#getDirectoryFromPath(getCurrentTemplatePath())#"
          componentPath="cf-semver"
          recurse="false"
          returnvariable="results" />

<cfoutput> #results.getResultsOutput('extjs')# </cfoutput>