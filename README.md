# LRKeywordImporter
Lightroom plugin to allow importing of keywords from a CSV.

# WARNING. This is experimental software that has not been thoroughly tested. 

## Details

This is a  simple plugin for Lightroom that will read in a CSV file containing a list of filenames and keywords and attach the keywords to the images. 

The expected CSV format is: 

`absolutePathToFilename|List,of,keywords`

For example: 

`c:\media\photos\IMG_3214.JPG|Brisbane, Australia, cockatoo, bird, animal`

## Instructions

1. Add the plugin as usual
1. Select Library mode
1. Select 'Library' from the top menu and open Keyword Importer from the Plug-in Extras item at the bottom. 
1. Click 'Select file' to open the file selection dialog and find your .csv file. 
1. Hit OK and the keywords will start importing. 

### Notes/warnings

- Only tested on Windows. 
- This /should/ only add new tags but it has not been tested thoroughly & may alter/delete existing tags. 
- Has not been tested on CSVs above a few hundred lines. Large CSVs may cause problems.
- When you click OK to start the import, the dialog will close and the improt will start running in the background. If you view the Keyword List you should see the new keywords be added. 
