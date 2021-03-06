# XHTMLConverterCLI
Desktop application to convert (Moonshine)Visual Editor XML file to PrimeFaces XHTML using a CLI by using the common [VisualEditorConverterLib](https://github.com/prominic/VisualEditorConverterLib) also used by [Moonshine IDE](https://github.com/prominic/Moonshine-IDE)

## CLI Arguments
Standard commands for both Unix and Windows platforms
- `--publish-to-primefaces`: Followed by *source* .xml file path and *destination* .xhtml file path; Or, *source* directory path and (optional)*destination* directory path for bulk conversion including sub-directories. If *destination* directory path not given during directory-conversion, xHTML file will generate to each XML file's corresponding directory
- `--overwrite`: Mark destination file (if already exists) to overwrite - default `false`

### Example On Windows
Sending command to convert nsf-xml to xhtml (use of double-quote is important to the platform)

**Single File Conversion:**
```
"c:\Program Files (x86)\XHTMLConverterCLI\XHTMLConverterCLI.exe" --publish-to-primefaces "path-to-source-nsf-file.xml" "path-to-destination-nsf-file.xhtml"
```

**Directory Conversion:**
```
"c:\Program Files (x86)\XHTMLConverterCLI\XHTMLConverterCLI.exe" --publish-to-primefaces "path-to-source-directory" [optional "path-to-destination-directory"]
```

### Example On Unix
Sending command to convert nsf-xml to xhtml

**Single File Conversion:**
```
open -a 'XHTMLConverterCLI.app' --args --publish-to-primefaces 'path-to-source-nsf-file.xml' 'path-to-destination-nsf-file.xhtml'
```
An alternative option is as follows, this shall work as long as we keep the executable non-sandbox:
```
'XHTMLConverterCLI.app/Contents/MacOS/XHTMLConverterCLI' --publish-to-primefaces 'path-to-source-nsf-file.xml' 'path-to-destination-nsf-file.xhtml'
```

**Directory Conversion:**
```
'XHTMLConverterCLI.app/Contents/MacOS/XHTMLConverterCLI' --publish-to-primefaces 'path-to-source-directory' [optional 'path-to-destination-directory']
```

#### Log
Log file generates by current date/job to following place:

**Windows:**
```
C:\Users\$userName\AppData\Roaming\net.prominic.xhtmlConverterCLI\Local Store
```
**OSX:**
```
/Users/$userName/Library/Application Support/net.prominic.xhtmlConverterCLI/Local Store
```