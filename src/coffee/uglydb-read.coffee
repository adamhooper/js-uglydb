# Only for people _not_ using RequireJS.
#
# Usage:
#
# <script src="/path/to/uglydb-read.no-require.js"></script>
# <script>
#   var uglyJson = ...;
#   var json = uglyDb.read(uglyJson);
# </script>
read = requirejs('./uglydb/read')
window.uglyDb = { read }
