def filter_pname: select(
	# Packages that do not have a pname are not very interesting.
	(.pname != null) and
	# Likewise for wrapper packages.
	(.pname | endswith("-wrapper") | not)
);

# The package name sometimes has other pre/suffixed strings not present in the
# pname or version fields, so we escape the version string and remove it from
# the name instead of using a possibly incomplete pname.
def realname:
	# https://stackoverflow.com/a/70483232
	(.version
	| reduce ("\\\\", "\\*", "\\^", "\\?", "\\+", "\\.", "\\!", "\\{", "\\}", "\\[", "\\]", "\\$", "\\|", "\\(", "\\)") as $c (
		.;
		gsub($c; $c)
	)) as $version |

	.name
	| sub("-\($version).*"; "")

	# Python and perl packages are prefixed with `$interpreter-$version-`,
	# which is incremented whenever the interpreter version changes and
	# that produces a lot of noise when the packages are not updated, but
	# the interpreters are.
	| sub("^python([0-9]+.?)+-"; "python-")
	| sub("^perl([0-9]+.?)+-"; "perl-");

# There may be packages with the same name but different versions present, so
# to avoid incorrect version comparisons due to overlapping package names, we
# split them by major version.
def version_to_side($side): {
	(realname): {
		(.version as $version | $version | split(".") | .[0]): {
			($side): .version
		}
	}
};

def ansi: {
	red: "\u001b[31m",
	green: "\u001b[32m",
	blue: "\u001b[34m",
	brred: "\u001b[91m",
	brgreen: "\u001b[92m",
	brblue: "\u001b[94m",
	_reset: "\u001b[0m"
};

# If a package is in our PATH, colour it with $path_colour, otherwise
# $regular_colour.
([.[2].[].env] | map(filter_pname | realname)) as $path |
def colourise($path_colour; $regular_colour):
	if IN($path[]) then
		$path_colour + . + ansi._reset
	else
		$regular_colour + . + ansi._reset
	end;


([.[0].[].env] | map(filter_pname | version_to_side("left"))) + ([.[1].[].env] | map(filter_pname | version_to_side("right")))
| reduce .[] as $item ({}; . * $item)

# NOTE: Handles major version changes assuming that there are only two packages
# changing major version in order to prevent a major version upgrade to look
# like a package removal and addition. This assumption may not always hold.
| . + map_values(
	map(.)
	| select((length == 2) and (.[0].left != null) and (.[0].right == null) and (.[1].left == null) and (.[1].right != null))
	| { (.[0].left[0:1]): { left: .[0].left, right: .[1].right } }
)

| to_entries
| map(
	.key as $name
	| .value[]
	| select(.left != .right)
	# Each package name may have a number of different kinds of updates for
	# various different versions, so we group them here for easier
	# filtering.
	| if .left == null and .right != null then
		{ type: "added", name: $name, name_colour: $name | colourise(ansi.brgreen; ansi.green), content: .right }
	elif .left != null and .right == null then
		{ type: "removed", name: $name, name_colour: $name | colourise(ansi.brred; ansi.red), content: .left }
	else
		{ type: "updated", name: $name, name_colour: $name | colourise(ansi.brblue; ansi.blue), content: "\(.left) -> \(.right)" }
	end
)
| group_by(.type)
| map(
	.[0].type as $type
	| group_by(.name)
	| map("  \(.[0].name_colour): \(map(.content) | sort | join(", "))")
	| if length > 0 then [ "\(length) \($type) packages:" ] + . + [ "" ] else empty end
)
| add
| .[0:-1]
| join("\n")
