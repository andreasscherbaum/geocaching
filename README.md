# geocaching
Tools for Geocaching

## transform-loc-to-gpx.pl

Apps like OsmAnd require .gpx files in order to add coordinates on the map.
The Geocaching website offers .loc files for download, where the file includes the following information:

* Name of the Geocache
* Coordinates
* URL of the cache on the Geocaching website

Downloading the .loc file will always save the file as "geocaching.loc", the browser might add an ascending number in case the file already exists.

The _transform-loc-to-gpx.pl_ script will rename the file based on the Geocaching ID, and convert it using the _gpsbabel_ into a .gpx file.
